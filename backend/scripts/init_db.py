"""
初始化数据库
"""
from app.database import engine, Base
from app.models.user import User, Transaction, Subscription

def init_db():
    """创建所有表"""
    Base.metadata.create_all(bind=engine)
    print("数据库表创建成功！")

if __name__ == "__main__":
    init_db()

