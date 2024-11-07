#!/bin/bash

NODENAME="dria"
GREENCOLOR="\e[32m"
DEFAULTCOLOR="\e[0m"

setup() {
    curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash
    sleep 3

    echo "更新并升级软件包..."
    sudo apt update -y && sudo apt upgrade -y

    cd ~
    if [ -d "node" ]; then
        echo "'node' 目录已存在。"
    else
        mkdir node
        echo "已创建 'node' 目录。"
    fi
    cd node

    if [ -d "$NODENAME" ]; then
        echo "'$NODENAME' 目录已存在。"
    else
        mkdir $NODENAME
        echo "已创建 '$NODENAME' 目录。"
    fi
    cd $NODENAME
}

backUp(){
    pwd
    echo "备份现有环境文件"
    
    if [ -f ".env" ]; then
        echo "当前目录中已存在 .env 文件，跳过备份。"
    else
        if [ -f "dkn-compute-node/.env" ]; then
            cp dkn-compute-node/.env .
            echo "从 dkn-compute-node 备份 .env 文件。"
        else
            echo "dkn-compute-node 中不存在 .env 文件，跳过备份。"
        fi
    fi
    
    if [ -d "dkn-compute-node" ]; then
        rm -rf dkn-compute-node
        echo "已删除 dkn-compute-node 目录。"
    else
        echo "dkn-compute-node 目录不存在，跳过删除。"
    fi
    
    if [ -f "dkn-compute-node.zip" ]; then
        rm dkn-compute-node.zip
        echo "已删除 dkn-compute-node.zip 文件。"
    else
        echo "dkn-compute-node.zip 文件不存在，跳过删除。"
    fi

    if ! command -v lsof &> /dev/null; then
        echo "lsof 未安装。正在安装..."
        sudo apt-get install -y lsof
        echo "lsof 安装完成。"
    else
        echo "lsof 已安装。"
    fi

    process_name="ollama"
    process_id=$(lsof -t -i | grep -i "$process_name")
    if [ -z "$process_id" ]; then
        echo "$process_name 未运行或未使用任何端口。"
    else
        echo "$process_name 正在运行，PID 为: $process_id。正在终止进程..."
        kill -9 "$process_id"
        
        if [ $? -eq 0 ]; then
            echo "$process_name 进程已终止。"
        else
            echo "终止 $process_name 进程失败。"
        fi
    fi
}

installRequirements(){
    echo "安装 $NODENAME 计算节点"
    if [ ! -d "dkn-compute-node" ] && [ ! -f "dkn-compute-node.zip" ]; then
        echo "下载 dkn-compute-node.zip"
        ARCH=$(uname -m)

        if [ "$ARCH" == "arm64" ]; then
            echo "架构为 arm64，下载 arm64 版本。"
            curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-arm64.zip
        elif [ "$ARCH" == "x86_64" ]; then
            echo "架构为 x86_64，下载 amd64 版本。"
            curl -L -o dkn-compute-node.zip https://github.com/firstbatchxyz/dkn-compute-launcher/releases/latest/download/dkn-compute-launcher-linux-amd64.zip
        else
            echo "未知架构: $ARCH。退出。"
            exit 1
        fi
        echo "解压 dkn-compute-node.zip"
        unzip dkn-compute-node.zip 
        rm dkn-compute-node.zip 
        cd dkn-compute-node
    else
        echo "dkn-compute-node 文件夹已存在或 dkn-compute-node.zip 已下载。"
        if [ -d "dkn-compute-node" ]; then
            cd dkn-compute-node
        fi
    fi
    echo "恢复备份环境文件。"
    cp -r ../.env .
    echo "$NODENAME 计算节点已安装"
}

finish() {
    if ! [ -f help.txt ]; then
        {
            echo "设置完成"
            echo "您的 $NODENAME 路径在 ~/node/dria/"
            echo ""
            echo "按照以下步骤启动节点："
            echo "启动节点请运行 ./dkn-compute-launcher"
            echo "-> 输入您的 DKN 钱包密钥 / 私钥"
            echo "-> 在选择模型之前，请查看团队指南 https://github.com/0xmoei/Dria-Node 获取建议"
            echo "-> 选择一个模型，推荐使用 Gemini + Llama3_1_8B 模型"
            echo "-> 获取 Gemini APIKEY: https://aistudio.google.com/app/apikey"
            echo "-> 获取 Jina API: https://jina.ai/embeddings/（可选，按 Enter 跳过）"
            echo "-> 获取 Serper API: https://serper.dev/api-key（可选，按 Enter 跳过）"
            echo "-> 完成。现在节点将开始下载模型文件并测试。每个模型必须通过测试，这取决于您的系统配置。"
            echo ""
            echo "有用的命令："
            echo "- 重启 Dria 节点：'./dkn-compute-launcher'"
            echo "- 删除节点：'cd \$HOME/node/$NODENAME && rm -r dkn-compute-node'"
            echo "- 再次查看此帮助：'cat ~/node/dria/dkn-compute-node/help.txt'"
        } > help.txt
    fi
    cat help.txt
}

run() {
    read -p "是否要运行它？(y/n): " response
    if [[ $response == "y" ]]; then
        ./dkn-compute-launcher
    else
        echo "继续"
    fi
}

setup
backUp
installRequirements
finish
run
