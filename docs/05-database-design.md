# 数据库设计说明书

## 1. 设计目标

本数据库设计用于支撑第一迭代的以下功能：

- 用户登录与身份认证
- 用户、角色和权限管理
- AI 会话管理
- AI 消息记录

## 2. 第一迭代核心表

第一迭代计划设计以下数据表：

- `sys_tenant`：租户表
- `sys_user`：用户表
- `sys_role`：角色表
- `sys_permission`：权限表
- `sys_user_role`：用户角色关联表
- `sys_role_permission`：角色权限关联表
- `ai_conversation`：AI 会话表
- `ai_message`：AI 消息表