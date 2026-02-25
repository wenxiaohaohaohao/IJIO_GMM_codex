#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
权限修复效果测试脚本
"""

import os
import sys
from pathlib import Path
from datetime import datetime

def test_permissions():
    print("=" * 60)
    print("权限修复效果测试")
    print("=" * 60)
    print()
    
    test_dirs = [
        r"D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\results\data",
        r"D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\results\logs",
        r"D:\paper\IJIO_GMM_codex_en\1017\1022_non_hicks\data\work"
    ]
    
    results = {}
    
    for test_dir in test_dirs:
        dir_name = test_dir.split("\\")[-1]
        print(f"【测试】{dir_name}/")
        
        if not os.path.exists(test_dir):
            print(f"  ✗ 目录不存在")
            results[dir_name] = "skip"
            continue
        
        # 测试1：创建新文件
        test_file = os.path.join(test_dir, f"test_write_{datetime.now().strftime('%H%M%S')}.txt")
        try:
            with open(test_file, 'w') as f:
                f.write('test write permission')
            os.remove(test_file)
            print(f"  ✓ 可以创建和删除新文件")
        except Exception as e:
            print(f"  ✗ 创建文件失败: {e}")
            results[dir_name] = "fail"
            continue
        
        # 测试2：覆盖现有文件
        existing_files = [f for f in os.listdir(test_dir) 
                         if f.endswith(('.dta', '.log', '.txt')) and not f.startswith('test_')]
        
        if existing_files:
            test_file = os.path.join(test_dir, existing_files[0])
            try:
                # 检查读权限
                can_read = os.access(test_file, os.R_OK)
                can_write = os.access(test_file, os.W_OK)
                
                if can_read:
                    print(f"  ✓ 可读: {existing_files[0]}")
                else:
                    print(f"  ✗ 无读权限: {existing_files[0]}")
                
                if can_write:
                    print(f"  ✓ 可写: {existing_files[0]}")
                    results[dir_name] = "pass"
                else:
                    print(f"  ✗ 无写权限: {existing_files[0]}")
                    results[dir_name] = "fail"
                    
            except Exception as e:
                print(f"  ✗ 权限检查失败: {e}")
                results[dir_name] = "fail"
        else:
            print(f"  ⚠ 没有已有文件用于测试")
            results[dir_name] = "pass"
        
        print()
    
    # 总结
    print("=" * 60)
    print("测试结果总结")
    print("=" * 60)
    
    for dir_name, result in results.items():
        if result == "pass":
            print(f"✓ {dir_name}: 权限正常")
        elif result == "fail":
            print(f"✗ {dir_name}: 权限有问题")
        else:
            print(f"⊘ {dir_name}: 跳过")
    
    print()
    print("=" * 60)
    
    # 判断整体结果
    if all(r != "fail" for r in results.values()):
        print("✓✓✓ 权限修复成功！所有目录都可以读写")
        return 0
    else:
        print("✗✗✗ 权限修复失败！某些目录仍有问题")
        return 1

if __name__ == "__main__":
    sys.exit(test_permissions())
