#!/bin/bash

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
  echo -e "\033[31m请以root权限运行此脚本.\033[0m"
  exit
fi

# 自动检查并授予 iptables 和 ip6tables 所需的权限
if ! command -v iptables >/dev/null 2>&1; then
  echo -e "\033[31miptables 未安装，请安装 iptables 后重试.\033[0m"
  exit 1
fi

if ! command -v ip6tables >/dev/null 2>&1; then
  echo -e "\033[31mip6tables 未安装，请安装 ip6tables 后重试.\033[0m"
  exit 1
fi

# 定义颜色
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PURPLE='\033[35m'
RESET='\033[0m'

# 校验端口输入是否符合标准
validate_ports() {
    local ports=$1
    # 匹配单个端口、多个端口或端口范围
    if [[ $ports =~ ^([0-9]{1,5}(-[0-9]{1,5})?)(,[0-9]{1,5}(-[0-9]{1,5})?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

# 批量删除规则
delete_rules() {
    local ip_choice=$1
    local rule_nums=$2

    # 删除规则函数
    delete_rule() {
        local ip_choice=$1
        local rule_num=$2
        case $ip_choice in
            1) iptables -t nat -D PREROUTING $rule_num ;;
            2) ip6tables -t nat -D PREROUTING $rule_num ;;
            3)
                iptables -t nat -D PREROUTING $rule_num
                ip6tables -t nat -D PREROUTING $rule_num
                ;;
            *) echo -e "${RED}无效选项，请重试。${RESET}" ;;
        esac
    }

    IFS=',' read -ra nums <<< "$rule_nums"

    for num in "${nums[@]}"; do
        if [[ $num =~ ^[0-9]+-[0-9]+$ ]]; then
            range=(${num//-/ })
            start=${range[0]}
            end=${range[1]}
            if [ $start -le $end ]; then
                for ((i=$end; i>=$start; i--)); do
                    delete_rule $ip_choice $i
                done
            else
                echo -e "${RED}起始规则编号大于结束规则编号，请检查输入。${RESET}"
            fi
        else
            delete_rule $ip_choice $num
        fi
    done
}

# 添加重定向规则
add_redirect_rules() {
    local ip_choice=$1
    local ports=$2
    local target_port=$3
    local proto=$4

    # 处理端口范围的格式
    process_ports() {
        local range=$1
        # 将 `400-500` 转换为 `400:500`
        echo "${range//-/:}"
    }

    # 添加规则函数
    add_rule() {
        local ip_choice=$1
        local port_range=$2
        local target_port=$3
        local proto=$4
        case $ip_choice in
            1)
                iptables -t nat -A PREROUTING -i eth0 -p $proto --dport $port_range -j REDIRECT --to-ports $target_port
                ;;
            2)
                ip6tables -t nat -A PREROUTING -i eth0 -p $proto --dport $port_range -j REDIRECT --to-ports $target_port
                ;;
            3)
                iptables -t nat -A PREROUTING -i eth0 -p $proto --dport $port_range -j REDIRECT --to-ports $target_port
                ip6tables -t nat -A PREROUTING -i eth0 -p $proto --dport $port_range -j REDIRECT --to-ports $target_port
                ;;
            *)
                echo -e "${RED}无效选项，请重试。${RESET}"
                ;;
        esac
    }

    # 处理多个单端口的规则
    add_multiport_rule() {
        local ip_choice=$1
        local ports=$2
        local target_port=$3
        local proto=$4
        case $ip_choice in
            1)
                iptables -t nat -A PREROUTING -i eth0 -p $proto -m multiport --dports $ports -j REDIRECT --to-ports $target_port
                ;;
            2)
                ip6tables -t nat -A PREROUTING -i eth0 -p $proto -m multiport --dports $ports -j REDIRECT --to-ports $target_port
                ;;
            3)
                iptables -t nat -A PREROUTING -i eth0 -p $proto -m multiport --dports $ports -j REDIRECT --to-ports $target_port
                ip6tables -t nat -A PREROUTING -i eth0 -p $proto -m multiport --dports $ports -j REDIRECT --to-ports $target_port
                ;;
            *)
                echo -e "${RED}无效选项，请重试。${RESET}"
                ;;
        esac
    }

    IFS=',' read -ra port_ranges <<< "$ports"
    if [[ $ports =~ ^[0-9]{1,5}(,[0-9]{1,5})*$ ]]; then
        # 处理多个单端口情况
        add_multiport_rule $ip_choice "$ports" "$target_port" "$proto"
    else
        for port_range in "${port_ranges[@]}"; do
            if [[ $port_range =~ ^[0-9]{1,5}(-[0-9]{1,5})?$ ]]; then
                # 处理端口范围格式
                formatted_range=$(process_ports "$port_range")
                add_rule $ip_choice "$formatted_range" "$target_port" "$proto"
            else
                echo -e "${RED}端口范围格式无效，请检查输入。${RESET}"
            fi
        done
    fi
}

# 菜单界面
while true; do
    clear
    echo -e "${BLUE}========= 端口重定向脚本 =========${RESET}"
    echo -e "${YELLOW}1.${RESET} 添加端口重定向规则 (TCP)"
    echo -e "${YELLOW}2.${RESET} 添加端口重定向规则 (UDP)"
    echo -e "${YELLOW}3.${RESET} 查看现有的重定向规则"
    echo -e "${YELLOW}4.${RESET} 删除指定规则"
    echo -e "${YELLOW}5.${RESET} 退出"
    echo -e "${BLUE}=================================${RESET}"
    read -p "请选择操作: " choice

    case $choice in
        1)
            proto="tcp"
            ;;
        2)
            proto="udp"
            ;;
        3)
            echo -e "${BLUE}现有的 iptables 规则 (IPv4):${RESET}"
            iptables -t nat -L -v -n --line-numbers
            echo ""
            echo -e "${BLUE}现有的 ip6tables 规则 (IPv6):${RESET}"
            ip6tables -t nat -L -v -n --line-numbers
            read -p "按任意键返回菜单..."
            continue
            ;;
        4)
            echo -e "${PURPLE}选择要删除规则的 IP 协议：${RESET}"
            echo -e "${YELLOW}1.${RESET} 删除 IPv4 规则"
            echo -e "${YELLOW}2.${RESET} 删除 IPv6 规则"
            echo -e "${YELLOW}3.${RESET} 删除两者规则"
            read -p "请选择协议: " del_choice

            case $del_choice in
                1)
                    echo -e "${RED}请输入规则编号 (删除 IPv4 规则，可以用逗号分隔多个规则编号或范围):${RESET}"
                    read -p "规则编号: " rule_nums
                    delete_rules 1 "$rule_nums"
                    echo -e "${GREEN}IPv4 规则已删除。${RESET}"
                    ;;
                2)
                    echo -e "${RED}请输入规则编号 (删除 IPv6 规则，可以用逗号分隔多个规则编号或范围):${RESET}"
                    read -p "规则编号: " rule_nums
                    delete_rules 2 "$rule_nums"
                    echo -e "${GREEN}IPv6 规则已删除。${RESET}"
                    ;;
                3)
                    echo -e "${RED}请输入规则编号 (删除 IPv4 规则，可以用逗号分隔多个规则编号或范围):${RESET}"
                    read -p "规则编号: " rule_nums_ipv4
                    delete_rules 1 "$rule_nums_ipv4"
                    echo -e "${GREEN}IPv4 规则已删除。${RESET}"

                    echo -e "${RED}请输入规则编号 (删除 IPv6 规则，可以用逗号分隔多个规则编号或范围):${RESET}"
                    read -p "规则编号: " rule_nums_ipv6
                    delete_rules 2 "$rule_nums_ipv6"
                    echo -e "${GREEN}IPv6 规则已删除。${RESET}"
                    ;;
                *)
                    echo -e "${RED}无效选项，请重试。${RESET}"
                    continue
                    ;;
            esac
            read -p "按任意键返回菜单..."
            continue
            ;;
        5)
            echo -e "${GREEN}退出脚本。${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重试。${RESET}"
            continue
            ;;
    esac

    # 提示输入要应用的规则 (IPv4, IPv6 或者两者)
    echo -e "${PURPLE}选择要应用规则的 IP 协议：${RESET}"
    echo -e "${YELLOW}1.${RESET} IPv4"
    echo -e "${YELLOW}2.${RESET} IPv6"
    echo -e "${YELLOW}3.${RESET} 两者"
    read -p "请选择协议: " ip_choice

    # 提示输入端口范围或单个端口
    while true; do
        read -p "请输入端口范围或单个端口 (例如 20000-50000 或 80,443): " ports
        if validate_ports "$ports"; then
            break
        else
            echo -e "${RED}端口范围格式无效，请检查输入。${RESET}"
        fi
    done

    while true; do
        read -p "请输入目标端口: " target_port
        if [[ $target_port =~ ^[0-9]{1,5}$ ]] && [ $target_port -ge 1 ] && [ $target_port -le 65535 ]; then
            break
        else
            echo -e "${RED}目标端口格式无效，请输入一个 1 到 65535 之间的端口。${RESET}"
        fi
    done

    # 添加重定向规则
    add_redirect_rules $ip_choice "$ports" "$target_port" "$proto"
    echo -e "${GREEN}规则已添加。${RESET}"
    read -p "按任意键返回菜单..."
done
