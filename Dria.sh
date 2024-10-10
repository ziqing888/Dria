#!/bin/bash

# 定义文本格式
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
SUCCESS_COLOR='\033[1;32m'
WARNING_COLOR='\033[1;33m'
ERROR_COLOR='\033[1;31m'
INFO_COLOR='\033[1;36m'
MENU_COLOR='\033[1;34m'

# 自定义状态显示函数
display_status() {
    local message="$1"
    local status="$2"
    case $status in
        "error")
            echo -e "${ERROR_COLOR}${BOLD}❌ 错误: ${message}${NORMAL}"
            ;;
        "warning")
            echo -e "${WARNING_COLOR}${BOLD}⚠️ 警告: ${message}${NORMAL}"
            ;;
        "success")
            echo -e "${SUCCESS_COLOR}${BOLD}✅ 成功: ${message}${NORMAL}"
            ;;
        "info")
            echo -e "${INFO_COLOR}${BOLD}ℹ️ 信息: ${message}${NORMAL}"
            ;;
        *)
            echo -e "${message}"
            ;;
    esac
}

# 确保脚本以 root 用户身份运行
if [[ $EUID -ne 0 ]]; then
    display_status "请以 root 用户权限运行此脚本。" "error"
    exit 1
fi

# 第一步：更新系统并安装依赖项
setup_prerequisites() {
    display_status "检查并安装所需的系统依赖项..." "info"
    sudo apt update -y && sudo apt upgrade -y
    sudo apt-get dist-upgrade -y
    sudo apt autoremove -y

    local dependencies=("curl" "ca-certificates" "gnupg" "wget" "unzip")
    for package in "${dependencies[@]}"; do
        if ! dpkg -l | grep -q "^ii\s\+$package"; then
            display_status "正在安装 $package..." "info"
            sudo apt install -y $package
        else
            display_status "$package 已经安装，跳过。" "success"
        fi
    done
}

# 安装 Docker 环境
install_docker() {
    display_status "正在安装 Docker..." "info"
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg
    done

    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    docker --version && display_status "Docker 安装成功。" "success" || display_status "Docker 安装失败。" "error"
}

# 安装 Ollama
install_ollama() {
    display_status "正在安装 Ollama..." "info"
    curl -fsSL https://ollama.com/install.sh | sh && display_status "Ollama 安装成功。" "success" || display_status "Ollama 安装失败。" "error"
}

# 下载并安装 Dria 节点
install_dria_node() {
    display_status "下载并安装 Dria 节点..." "info"
    cd $HOME

    # 检查文件是否已经存在，如果存在则删除以避免重复下载
    if [[ -f "dkn-compute-node.zip" ]]; then
        display_status "发现已有的 Dria 节点压缩文件，正在删除以避免重复下载..." "info"
        rm -f dkn-compute-node.zip
    fi

    # 下载 Dria 节点文件
    curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip
    
    # 检查解压目录是否存在，如果存在则删除以避免重复安装
    if [[ -d "dkn-compute-node" ]]; then
        display_status "发现已有的 Dria 节点目录，正在删除以避免重复安装..." "info"
        rm -rf dkn-compute-node
    fi

    # 解压文件
    unzip dkn-compute-node.zip || { display_status "文件解压失败，请检查错误并重试。" "error"; return; }
    display_status "Dria 节点安装完成。" "success"
}

# 运行 Dria 节点
run_dria_node() {
    display_status "正在启动 Dria 节点..." "info"
    cd $HOME/dkn-compute-node
    ./dkn-compute-launcher || { display_status "Dria 节点启动失败，请检查错误并重试。" "error"; return; }
    display_status "Dria 节点已成功启动。" "success"
}

# 主菜单功能
main_menu() {
    while true; do
        clear
        echo -e "${MENU_COLOR}${BOLD}============================ Dria 节点管理工具 ============================${NORMAL}"
        echo -e "${MENU_COLOR}请选择操作:${NORMAL}"
        echo -e "${MENU_COLOR}1. 更新系统并安装依赖项${NORMAL}"
        echo -e "${MENU_COLOR}2. 安装 Docker 环境${NORMAL}"
        echo -e "${MENU_COLOR}3. 安装 Ollama${NORMAL}"
        echo -e "${MENU_COLOR}4. 下载并安装 Dria 节点${NORMAL}"
        echo -e "${MENU_COLOR}5. 运行 Dria 节点${NORMAL}"
        echo -e "${MENU_COLOR}6. 退出${NORMAL}"
        read -p "请输入选项（1-6）: " OPTION

        case $OPTION in
            1) setup_prerequisites ;;
            2) install_docker ;;
            3) install_ollama ;;
            4) install_dria_node ;;
            5) run_dria_node ;;
            6) exit 0 ;;
            *) display_status "无效选项，请重试。" "error" ;;
        esac
        read -n 1 -s -r -p "按任意键返回主菜单..."
    done
}

# 启动主菜单
main_menu
