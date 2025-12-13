"""
最小化测试：验证预扣交易的基础语义（不依赖外部模型 API / Redis）
"""

import uuid

import pytest

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import Base
from app.models.user import User, Transaction, SubscriptionType
from app.services.billing_service import billing_service


@pytest.fixture()
def db_session():
    """
    使用独立的 SQLite 内存库，避免依赖本机 Postgres 的真实表结构。
    （create_all 不会自动做 schema 迁移；如果用户本机已存在旧表，会导致新增列不存在）
    """
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


def test_pending_consume_affects_available_balance(db_session):
    db = db_session
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        username=f"u_{user_id[:8]}",
        email=f"{user_id[:8]}@example.com",
        hashed_password="x",
        phone_number=None,
        balance=10.0,
        subscription_type=SubscriptionType.NONE,
        subscription_expires_at=None,
    )
    db.add(user)
    db.commit()

    task_id = str(uuid.uuid4())
    tx = billing_service.create_pending_consume_transaction(
        db=db,
        user_id=user_id,
        task_id=task_id,
        cost=3.0,
        description="test",
    )
    db.commit()

    available = billing_service.get_available_balance(db, user_id)
    assert available == pytest.approx(7.0)

    # 结算后：balance 真正扣减
    billing_service.settle_pending_consume_transaction(db=db, tx=tx)
    db.commit()
    db.refresh(user)
    db.refresh(tx)
    assert user.balance == pytest.approx(7.0)
    assert tx.status == "completed"


def test_cancel_pending_does_not_change_balance(db_session):
    db = db_session
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        username=f"u_{user_id[:8]}",
        email=f"{user_id[:8]}@example.com",
        hashed_password="x",
        phone_number=None,
        balance=10.0,
        subscription_type=SubscriptionType.NONE,
        subscription_expires_at=None,
    )
    db.add(user)
    db.commit()

    task_id = str(uuid.uuid4())
    tx = billing_service.create_pending_consume_transaction(
        db=db,
        user_id=user_id,
        task_id=task_id,
        cost=3.0,
        description="test_cancel",
    )
    db.commit()

    billing_service.cancel_pending_transaction(db=db, tx=tx, reason="fail")
    db.commit()
    db.refresh(user)
    db.refresh(tx)
    assert user.balance == pytest.approx(10.0)
    assert tx.status == "canceled"


def test_settle_is_idempotent(db_session):
    db = db_session
    user_id = str(uuid.uuid4())
    user = User(
        id=user_id,
        username=f"u_{user_id[:8]}",
        email=f"{user_id[:8]}@example.com",
        hashed_password="x",
        phone_number=None,
        balance=10.0,
        subscription_type=SubscriptionType.NONE,
        subscription_expires_at=None,
    )
    db.add(user)
    db.commit()

    task_id = str(uuid.uuid4())
    tx = billing_service.create_pending_consume_transaction(
        db=db,
        user_id=user_id,
        task_id=task_id,
        cost=3.0,
        description="test_idempotent",
    )
    db.commit()

    billing_service.settle_pending_consume_transaction(db=db, tx=tx)
    db.commit()
    db.refresh(user)
    assert user.balance == pytest.approx(7.0)

    # 再次结算不应重复扣减
    billing_service.settle_pending_consume_transaction(db=db, tx=tx)
    db.commit()
    db.refresh(user)
    assert user.balance == pytest.approx(7.0)


