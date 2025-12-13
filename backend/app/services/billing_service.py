"""
积分/余额扣费服务（支持“预扣 -> 成功结算 / 失败取消”）
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models.user import User, Transaction


@dataclass(frozen=True)
class BillingCheckResult:
    has_subscription: bool
    available_balance: float


class BillingService:
    """
    统一的扣费服务，提供：
    - 可用积分计算：balance + sum(pending consume amounts)
    - 预扣交易创建（pending）
    - 成功结算（completed + 扣减 User.balance）
    - 失败取消（canceled，不修改余额）
    """

    def get_available_balance(self, db: Session, user_id: str) -> float:
        user = db.query(User).filter(User.id == user_id).first()
        if not user:
            raise ValueError("用户不存在")

        pending_sum = (
            db.query(func.coalesce(func.sum(Transaction.amount), 0.0))
            .filter(
                Transaction.user_id == user_id,
                Transaction.transaction_type == "consume",
                Transaction.status == "pending",
            )
            .scalar()
        )
        # pending consume amount 通常为负数
        return float(user.balance + (pending_sum or 0.0))

    def create_pending_consume_transaction(
        self,
        *,
        db: Session,
        user_id: str,
        task_id: str,
        cost: float,
        description: str,
    ) -> Transaction:
        if cost <= 0:
            raise ValueError("cost 必须为正数")

        tx = Transaction(
            id=str(uuid.uuid4()),
            user_id=user_id,
            transaction_type="consume",
            amount=-float(cost),
            description=description,
            status="pending",
            related_task_id=task_id,
        )
        db.add(tx)
        return tx

    def settle_pending_consume_transaction(self, *, db: Session, tx: Transaction) -> None:
        """
        成功路径：结算扣费
        - tx.amount 为负数
        - user.balance += tx.amount
        - tx.status = completed

        并发安全（Postgres）：
        - 对 Transaction 行加 FOR UPDATE 行锁，确保只有一个 worker 能从 pending -> completed
        - 对 User 行加 FOR UPDATE 行锁，避免并发下 balance 读改写丢失更新
        """
        # 统一从 DB 重新加载并加锁，避免传入的 tx 是过期对象导致竞态
        locked_tx = (
            db.query(Transaction)
            .filter(Transaction.id == tx.id)
            .with_for_update()
            .first()
        )
        if not locked_tx:
            raise ValueError("交易记录不存在")
        if locked_tx.transaction_type != "consume":
            return
        if locked_tx.status != "pending":
            return

        locked_user = (
            db.query(User)
            .filter(User.id == locked_tx.user_id)
            .with_for_update()
            .first()
        )
        if not locked_user:
            raise ValueError("用户不存在")

        locked_user.balance += float(locked_tx.amount)
        locked_tx.status = "completed"

    def cancel_pending_transaction(self, *, db: Session, tx: Transaction, reason: Optional[str] = None) -> None:
        """
        失败路径：取消预扣（不修改余额）

        并发安全（Postgres）：
        - 对 Transaction 行加 FOR UPDATE 行锁，确保只会从 pending -> canceled 一次
        """
        locked_tx = (
            db.query(Transaction)
            .filter(Transaction.id == tx.id)
            .with_for_update()
            .first()
        )
        if not locked_tx:
            raise ValueError("交易记录不存在")
        if locked_tx.status != "pending":
            return
        locked_tx.status = "canceled"
        if reason:
            # 在 description 中追加原因，方便排查
            locked_tx.description = (locked_tx.description or "") + f" | canceled: {reason}"


billing_service = BillingService()


