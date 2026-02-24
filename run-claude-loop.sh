#!/bin/bash

# =============================================================================
# run-claude-loop.sh - Automated Claude Code Execution Loop
# =============================================================================
# This script runs Claude Code multiple times in a loop, with each iteration
# following the complete development workflow defined in CLAUDE.md.
#
# Usage: ./run-claude-loop.sh <number_of_iterations>
#
# Example: ./run-claude-loop.sh 5
#     This will run Claude Code 5 times, each time completing one task.
#
# =============================================================================

set -e

# =============================================================================
# Configuration
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="claude-loop.log"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
SESSION_LOG_FILE="claude-session-${TIMESTAMP}.log"

# Claude Code command
CLAUDE_CMD="claude"

# =============================================================================
# Helper Functions
# =============================================================================

# Print header
print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Print section
print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
}

# Print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Print info
print_info() {
    echo -e "${MAGENTA}ℹ $1${NC}"
}

# Log to file
log_message() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" >> "$LOG_FILE"
    echo "$msg" >> "$SESSION_LOG_FILE"
}

# Check if required files exist
check_required_files() {
    print_section "Checking required files..."

    local missing_files=()

    if [ ! -f "CLAUDE.md" ]; then
        missing_files+=("CLAUDE.md")
    fi

    if [ ! -f "task.json" ]; then
        missing_files+=("task.json")
    fi

    if [ ! -f "init.sh" ]; then
        missing_files+=("init.sh")
    fi

    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo ""
        echo "Please ensure you are in a project directory with all required files."
        exit 1
    fi

    print_success "All required files found"
}

# Count remaining tasks
count_remaining_tasks() {
    if [ ! -f "task.json" ]; then
        echo "0"
        return
    fi
    local count=$(grep -c '"passes": false' task.json 2>/dev/null || echo "0")
    echo "$count"
}

# Count completed tasks
count_completed_tasks() {
    if [ ! -f "task.json" ]; then
        echo "0"
        return
    fi
    local count=$(grep -c '"passes": true' task.json 2>/dev/null || echo "0")
    echo "$count"
}

# Get current task info
get_current_task_info() {
    if [ ! -f "task.json" ]; then
        echo "No task.json found"
        return
    fi

    # Find the first pending task with satisfied dependencies
    local task_id=$(jq -r '.tasks[] | select(.passes == false) | select(.dependencies | map(. as $dep | .tasks[] | select(.id == $dep and .passes == false) | .id) | length == 0) | .id' task.json 2>/dev/null | head -n 1)

    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        # If no task with satisfied dependencies, just get the first pending task
        task_id=$(jq -r '.tasks[] | select(.passes == false) | .id' task.json 2>/dev/null | head -n 1)
    fi

    if [ -z "$task_id" ] || [ "$task_id" = "null" ]; then
        echo "No pending tasks"
        return
    fi

    local title=$(jq -r ".tasks[] | select(.id == $task_id) | .title" task.json 2>/dev/null)
    local priority=$(jq -r ".tasks[] | select(.id == $task_id) | .priority" task.json 2>/dev/null)

    echo "#$task_id: $title ($priority)"
}

# Get the next task prompt for Claude
get_claude_prompt() {
    cat << 'INTERNAL_EOF'
请开始一个新的开发会话。

**重要：你必须严格遵循 CLAUDE.md 中定义的工作流程。**

请执行以下步骤：

1. **读取 CLAUDE.md** - 了解完整的工作流程和约束

2. **运行 init.sh** - 初始化开发环境

3. **读取 task.json** - 选择下一个任务
   - 只选择 passes: false 的任务
   - 优先级：critical > high > medium > low
   - 确保所有依赖任务（dependencies）已完成

4. **实现任务** - 按照 task.json 中的 steps 逐一实现

5. **测试验证** - 根据 testing.md 中的规则进行测试
   - 大幅修改：浏览器测试
   - 小修改：lint + build

6. **更新 progress.txt** - 记录工作内容

7. **更新 task.json** - 只修改 passes: false → passes: true

8. **Git 提交** - 提交所有更改
   - 代码修改
   - progress.txt
   - task.json
   - Commit 格式: "[ID] [标题] - completed"

⚠️ **阻塞处理**：
如果遇到以下情况，必须在 progress.txt 中记录阻塞信息并停止：
- 缺少环境配置（API密钥、数据库等）
- 外部服务不可用
- 测试无法进行
- 需求不明确

请现在开始执行，首先告诉我你选择了哪个任务。
INTERNAL_EOF
}

# Run single Claude session
run_claude_session() {
    local session_num=$1
    local total_sessions=$2

    print_header "Session $session_num of $total_sessions"

    # Log session start
    log_message "=== Starting Session $session_num of $total_sessions ==="

    # Show current task info
    print_section "Current Status"
    local remaining=$(count_remaining_tasks)
    local completed=$(count_completed_tasks)
    echo "  ✓ Completed tasks: $completed"
    echo "  ○ Remaining tasks: $remaining"
    local current_task=$(get_current_task_info)
    echo "  → Next task: $current_task"
    log_message "Status: $completed completed, $remaining remaining, Next: $current_task"

    # Check if all tasks are done
    if [ "$remaining" -eq 0 ]; then
        print_success "🎉 All tasks are complete!"
        log_message "All tasks complete - exiting loop"
        return 1
    fi

    # Run Claude Code interactively
    print_section "Starting Claude Code..."
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Claude will now execute the development workflow.${NC}"
    echo -e "${YELLOW}After Claude completes, return here to see the session summary.${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Save current task count for comparison
    local before_remaining=$remaining

    # Execute claude with the prompt
    # Using --permission-mode to auto-accept permissions
    local prompt=$(get_claude_prompt)

    if echo "$prompt" | $CLAUDE_CMD --permission-mode acceptEdits; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        print_success "Claude Code session completed"

        # Check if task was marked as complete
        local new_remaining=$(count_remaining_tasks)
        local new_completed=$(count_completed_tasks)

        echo ""
        print_section "Session Results"
        echo "  Tasks before: $before_remaining remaining, $completed completed"
        echo "  Tasks after:  $new_remaining remaining, $new_completed completed"

        if [ "$new_completed" -gt "$completed" ]; then
            local tasks_done=$((new_completed - completed))
            print_success "$tasks_done task(s) completed!"
            log_message "Session $session_num: $tasks_done task(s) completed ($before_remaining → $new_remaining remaining)"
        else
            print_warning "No task was marked as complete in this session"
            log_message "Session $session_num: No task completed"
        fi

        # Show latest commit if exists
        if git rev-parse --git-dir > /dev/null 2>&1; then
            echo ""
            print_section "Latest Git Commit"
            git log --oneline -1 2>/dev/null || echo "  No commits yet"
        fi

        log_message "=== Session $session_num completed ==="
        return 0
    else
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        print_error "Claude Code session exited with error"
        log_message "Session $session_num failed with error code $?"

        # Check if task was still completed despite error
        local new_remaining=$(count_remaining_tasks)
        local new_completed=$(count_completed_tasks)
        if [ "$new_completed" -gt "$completed" ]; then
            print_info "Note: A task was completed despite the error"
            log_message "Session $session_num: Task completed despite error"
            return 0
        fi

        return 1
    fi
}

# Show final summary
show_final_summary() {
    print_header "Final Summary"
    local total_iterations=$1
    local completed_count=$2

    local total_tasks=$(jq '.tasks | length' task.json 2>/dev/null || echo "unknown")
    local remaining=$(count_remaining_tasks)
    local completed=$(count_completed_tasks)

    echo -e "${BOLD}Sessions run:${NC}        $total_iterations"
    echo -e "${BOLD}Tasks completed:${NC}     $completed / $total_tasks"
    echo -e "${BOLD}Tasks remaining:${NC}     $remaining"
    echo ""

    if [ "$remaining" -eq 0 ]; then
        echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                    🎉 ALL TASKS COMPLETE! 🎉                       ║${NC}"
        echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    else
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║              Tasks remaining. Run again to continue.              ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════╝${NC}"
    fi

    echo ""
    echo -e "${BOLD}Log files:${NC}"
    echo "  Session log:  $SESSION_LOG_FILE"
    echo "  Main log:     $LOG_FILE"
    echo ""

    log_message "========== Loop completed ========== ($total_iterations sessions, $completed tasks completed)"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    # Parse arguments
    if [ $# -eq 0 ]; then
        echo "Usage: $0 <number_of_iterations>"
        echo ""
        echo "This script runs Claude Code multiple times, each time completing one task."
        echo ""
        echo "Arguments:"
        echo "  number_of_iterations    How many times to run Claude Code (default: until all tasks done)"
        echo ""
        echo "Options:"
        echo "  -h, --help              Show this help message"
        echo ""
        echo "Example:"
        echo "  $0 5    # Run Claude Code 5 times"
        echo "  $0 999  # Run until all tasks are complete (stops early when done)"
        echo ""
        exit 0
    fi

    # Handle help
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        main
        exit 0
    fi

    local MAX_ITERATIONS=$1

    # Validate input
    if ! [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
        print_error "Invalid number: $MAX_ITERATIONS"
        exit 1
    fi

    # Initialize log files
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== Starting Claude Loop ==========" > "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ========== Starting Claude Loop ==========" > "$SESSION_LOG_FILE"

    # Print banner
    clear
    print_header "Claude Code Automated Loop Runner"
    echo -e "${BOLD}Configuration:${NC}"
    echo "  Max iterations:   $MAX_ITERATIONS"
    echo "  Log file:         $LOG_FILE"
    echo "  Session log:      $SESSION_LOG_FILE"
    echo "  Claude command:   $CLAUDE_CMD"
    echo "  Permission mode:  acceptEdits (auto-accept)"
    echo ""

    # Check required files
    check_required_files

    # Show initial status
    print_section "Initial Status"
    local total_tasks=$(jq '.tasks | length' task.json 2>/dev/null || echo "unknown")
    local initial_remaining=$(count_remaining_tasks)
    local initial_completed=$(count_completed_tasks)
    echo "  Total tasks:      $total_tasks"
    echo "  Completed tasks:  $initial_completed"
    echo "  Remaining tasks:  $initial_remaining"
    echo ""

    if [ "$initial_remaining" -eq 0 ]; then
        print_success "All tasks are already complete!"
        exit 0
    fi

    # Show next task
    local next_task=$(get_current_task_info)
    print_info "Next task to work on: $next_task"
    echo ""

    # Confirm before starting
    echo -e "${YELLOW}About to run up to $MAX_ITERATIONS Claude Code sessions.${NC}"
    echo -e "${YELLOW}The loop will stop early if all tasks are completed.${NC}"
    echo -e "${YELLOW}Press Ctrl+C at any time to stop the loop.${NC}"
    echo ""
    read -p "$(echo -e ${GREEN}Press Enter to start...${NC})"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}                         STARTING LOOP                                    ${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Run loop
    local iteration=0
    local total_completed=0
    local continue_loop=true

    while [ $iteration -lt $MAX_ITERATIONS ] && [ "$continue_loop" = true ]; do
        iteration=$((iteration + 1))

        if run_claude_session $iteration $MAX_ITERATIONS; then
            local new_completed=$(count_completed_tasks)
            total_completed=$new_completed
        else
            # Session returned error or all tasks complete
            local remaining=$(count_remaining_tasks)
            if [ "$remaining" -eq 0 ]; then
                continue_loop=false
                break
            fi

            # Session failed but there are still tasks - ask whether to continue
            echo ""
            print_warning "Session exited with issues."
            echo ""
            read -p "$(echo -e ${YELLOW}Continue to next session? [Y/n]: ${NC})" continue_input
            if [[ "$continue_input" =~ ^[Nn]$ ]]; then
                log_message "Loop stopped by user after session $iteration"
                continue_loop=false
                break
            fi
        fi

        # Small delay between sessions
        if [ $iteration -lt $MAX_ITERATIONS ] && [ "$continue_loop" = true ]; then
            local remaining=$(count_remaining_tasks)
            if [ "$remaining" -gt 0 ]; then
                echo ""
                print_section "Preparing next session..."
                sleep 1
            else
                continue_loop=false
                break
            fi
        fi
    done

    # Final summary
    echo ""
    show_final_summary $iteration $total_completed
}

# Run main
main "$@"
