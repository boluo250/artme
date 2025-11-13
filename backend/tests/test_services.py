"""
服务层测试
"""
import pytest
from app.utils.prompts import prompt_manager


def test_prompt_manager_get_prompt():
    """测试 prompt 管理器"""
    prompt = prompt_manager.get_prompt("style_001", "a cute cat")
    assert "a cute cat" in prompt
    assert "anime" in prompt.lower() or "kawaii" in prompt.lower()


def test_prompt_manager_default():
    """测试默认 prompt"""
    prompt = prompt_manager.get_prompt(None, "a dog")
    assert "a dog" in prompt
    assert "cartoon" in prompt.lower()


def test_prompt_manager_add_template():
    """测试添加模板"""
    prompt_manager.add_template("test_style", "test template {user_prompt}")
    prompt = prompt_manager.get_prompt("test_style", "test input")
    assert "test template test input" == prompt

