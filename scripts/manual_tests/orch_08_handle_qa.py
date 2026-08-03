# scripts/manual_tests/orch_08_handle_qa.py
# 测试 Orchestrator.handle 单 QA Agent 真实调用
# 依赖：DeepSeek API / PostgreSQL:5433 / Milvus:19531
# 运行：conda activate hr_agent && python scripts/manual_tests/orch_08_handle_qa.py

import sys
import asyncio
sys.path.insert(0, ".")

from backend.core.orchestrator import get_orchestrator, AgentRequest, AgentType


def section(t):
    print("\n" + "=" * 60 + f"\n  {t}\n" + "=" * 60)


async def atest_handle_qa():
    section("handle 单 QA Agent：真实 DeepSeek + Milvus 调用")
    orch = get_orchestrator()

    req = AgentRequest(
        candidate_id="test-candidate-qa-001",
        tenant_id="tenant_default",
        session_id="orch-qa-test-001",
        agent_type=AgentType.QA,
        user_message="Java 中 HashMap 和 Hashtable 的区别是什么？",
    )

    print(f"thread_id : {req.thread_id}")
    print(f"发送问题  : {req.user_message}")
    print("等待响应…\n")

    resp = await orch.handle(req)

    print(f"success       : {resp.success}")
    print(f"agent_type    : {resp.agent_type}")
    print(f"fallback_used : {resp.fallback_used}")
    print(f"error_msg     : {resp.error_msg}")
    print(f"\ncontent:\n{resp.content[:500]}")

    assert resp.success,          f"QA Agent 执行失败: {resp.error_msg}"
    assert len(resp.content) > 20, "响应内容过短，疑似未正常返回"
    assert resp.agent_type == AgentType.QA


async def main():
    await atest_handle_qa()
    print("\n✅ handle 单 Agent 测试通过")


asyncio.run(main())
