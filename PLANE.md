# Plane Usage

This folder is mapped to Plane workspace `home`.

Use `C:\\AI tools\\Home\\plane.ps1` to create/update work items.

Examples:
- New task:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action new -Title "Task title" -Desc "Context..." -Labels "security,zfs" -Module "ZFS" -Priority high`
- Move task:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action move -Title WORK_ITEM_ID -State "In Progress"`
- Close task:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action close -Title WORK_ITEM_ID`
- Done (closes + ✅ comment):
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action done -Title WORK_ITEM_ID`
- Comment (✅ auto-closes):
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action comment -Title WORK_ITEM_ID -Desc "Done ✅"`
- Add labels:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action add-label -Title WORK_ITEM_ID -Labels "network,security"`
- Assign:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action assign -Title WORK_ITEM_ID -Assignee plane-bot`
- List:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action list -Title "keyword" -State "Todo" -Limit 20`
- Sync (update by exact title):
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action sync -Title "Exact task title" -State "In Progress" -Priority high`
- Create-or-sync:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action create-or-sync -Title "Exact task title" -Desc "..."`
- Daily summary:
  - `powershell -File C:\\AI tools\\Home\\plane.ps1 -Action daily-summary`
