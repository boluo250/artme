"""
错误码（MVP 版，<=20）：
仅定义 iOS 端需要明确区分的核心错误类型，并保留可扩展空间。
"""

from __future__ import annotations


class AvatarErrorCode:
    # 参数错误
    INVALID_ARGUMENT = "AVATAR_INVALID_ARGUMENT"
    UNSUPPORTED_INPUT = "AVATAR_UNSUPPORTED_INPUT"
    INPUT_TOO_LARGE = "AVATAR_INPUT_TOO_LARGE"

    # 鉴权/权限
    UNAUTHORIZED = "AVATAR_UNAUTHORIZED"
    FORBIDDEN = "AVATAR_FORBIDDEN"
    FEATURE_DISABLED = "AVATAR_FEATURE_DISABLED"

    # 计费（积分/会员）
    CREDITS_INSUFFICIENT = "AVATAR_CREDITS_INSUFFICIENT"
    SUBSCRIPTION_REQUIRED = "AVATAR_SUBSCRIPTION_REQUIRED"

    # 任务/生成结果
    NOT_FOUND = "AVATAR_NOT_FOUND"
    GENERATION_FAILED = "AVATAR_GENERATION_FAILED"
    MODEL_TIMEOUT = "AVATAR_MODEL_TIMEOUT"
    MODEL_REJECTED = "AVATAR_MODEL_REJECTED"

    # 系统
    RATE_LIMITED = "AVATAR_RATE_LIMITED"
    DEPENDENCY_UNAVAILABLE = "AVATAR_DEPENDENCY_UNAVAILABLE"
    INTERNAL_ERROR = "AVATAR_INTERNAL_ERROR"


DEFAULT_PUBLIC_MESSAGE: dict[str, str] = {
    AvatarErrorCode.INVALID_ARGUMENT: "请求参数不正确，请检查后重试",
    AvatarErrorCode.UNSUPPORTED_INPUT: "不支持的图片/内容格式，请更换后重试",
    AvatarErrorCode.INPUT_TOO_LARGE: "文件过大，请压缩后重试",
    AvatarErrorCode.UNAUTHORIZED: "请先登录",
    AvatarErrorCode.FORBIDDEN: "当前账号暂不可用，请联系客服",
    AvatarErrorCode.FEATURE_DISABLED: "该功能暂不可用",
    AvatarErrorCode.CREDITS_INSUFFICIENT: "积分不足，请充值后继续",
    AvatarErrorCode.SUBSCRIPTION_REQUIRED: "需要开通会员才能使用此功能",
    AvatarErrorCode.NOT_FOUND: "资源不存在或已过期",
    AvatarErrorCode.GENERATION_FAILED: "生成失败，请重试",
    AvatarErrorCode.MODEL_TIMEOUT: "生成超时，请重试",
    AvatarErrorCode.MODEL_REJECTED: "内容不符合要求，请调整后重试",
    AvatarErrorCode.RATE_LIMITED: "操作太频繁，请稍后再试",
    AvatarErrorCode.DEPENDENCY_UNAVAILABLE: "服务繁忙，请稍后重试",
    AvatarErrorCode.INTERNAL_ERROR: "系统异常，请稍后重试",
}


def default_message(code: str, fallback: str = "请求失败，请稍后重试") -> str:
    return DEFAULT_PUBLIC_MESSAGE.get(code, fallback)


def map_http_status_to_code(status_code: int) -> str:
    """
    当旧代码仍在 raise HTTPException(detail="...") 时，按 HTTP 状态码给一个合理的默认业务码。
    这样前端至少能稳定依赖 error.code 做 UI 行为分流。
    """
    if status_code in (400, 422):
        return AvatarErrorCode.INVALID_ARGUMENT
    if status_code == 401:
        return AvatarErrorCode.UNAUTHORIZED
    if status_code == 402:
        return AvatarErrorCode.CREDITS_INSUFFICIENT
    if status_code == 403:
        return AvatarErrorCode.FORBIDDEN
    if status_code == 404:
        return AvatarErrorCode.NOT_FOUND
    if status_code == 410:
        return AvatarErrorCode.FEATURE_DISABLED
    if status_code == 429:
        return AvatarErrorCode.RATE_LIMITED
    if status_code == 503:
        return AvatarErrorCode.DEPENDENCY_UNAVAILABLE
    return AvatarErrorCode.INTERNAL_ERROR


