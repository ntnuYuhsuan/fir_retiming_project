# FIR 濾波器 Retiming 專案

## 專案目標

本專案旨在演示如何透過 Retiming 技術優化一個 FIR (有限脈衝響應) 數位濾波器的時序性能。透過在原始 FIR 設計的關鍵路徑中策略性地插入暫存器 (流水線化)，我們可以縮短組合邏輯延遲，從而提高系統的最大工作頻率 (Fmax)，並可能降低功耗。

專案包含：
- 原始的 FIR 濾波器 Verilog 實現 (`src/fir_original.v`)。
- 經過 Retiming 優化的 FIR 濾波器 Verilog 實現 (`src/fir_retimed.v`)。
- 一個 Verilog 測試平台 (`src/fir_retiming_tb.v`) 用於驗證兩種設計的功能等效性並比較其輸出。
- 時序約束檔案 (`constraints/timing_constraints.sdc`)。
- Quartus Prime 專案設定腳本 (`scripts/quartus_project_setup.tcl`)。
- ModelSim 模擬腳本 (`simulation/modelsim.do`)。
- 一個 `Makefile` 和一個 Windows 批次處理檔 (`run_sim.bat`) 用於自動化編譯和模擬流程。

## 專案結構

```
fir_retiming_project/
├── src/                     # Verilog 原始碼
│   ├── fir_original.v       # 原始 FIR 濾波器
│   ├── fir_retimed.v        # Retiming 優化後的 FIR 濾波器
│   └── fir_retiming_tb.v    # 測試平台
├── constraints/             # 時序約束
│   └── timing_constraints.sdc
├── scripts/                 # 工具腳本
│   └── quartus_project_setup.tcl
├── simulation/              # 模擬相關檔案
│   ├── modelsim.do
│   └── waveform.do          # (可選的波形設定檔)
├── docs/                    # 設計文件
│   ├── design_spec.md
│   └── retiming_theory.md
├── output/                  # (模擬輸出目錄，由腳本創建)
├── logs/                    # (模擬日誌目錄，由腳本創建)
├── Makefile                 # GNU Make 檔案，用於編譯和模擬
├── run_sim.bat              # Windows 批次腳本，用於執行模擬
└── README.md                # 本檔案
```

## 如何執行

### 先決條件

1.  **Verilog 模擬器:**
    *   **Icarus Verilog (推薦):** 一個開源的 Verilog 模擬器。需將其執行檔路徑加入系統 PATH。
    *   **ModelSim:** Mentor Graphics (Siemens EDA) 的模擬器。
2.  **波形檢視器 (可選):**
    *   **GTKWave:** 一個開源的波形檢視器，常與 Icarus Verilog 搭配使用。需將其執行檔路徑加入系統 PATH。
3.  **FPGA 合成工具 (用於時序分析):**
    *   **Intel Quartus Prime:** 用於在 Intel FPGA 上合成並分析設計。
4.  **Git (版本控制):** 用於管理程式碼。
5.  **GNU Make (可選，用於 Makefile):** 如果您想使用 `Makefile`，需要安裝 Make。在 Windows 上，可以透過 MinGW 或 MSYS2 等工具獲得。

### 使用 Windows 批次腳本 (`run_sim.bat`) - 推薦用於快速驗證

1.  開啟命令提示字元 (cmd) 或 PowerShell。
2.  導航到專案根目錄: `cd path\to\fir_retiming_project`
3.  執行腳本: `.\run_sim.bat`
4.  按照提示選擇模擬器 (建議選擇 1. Icarus Verilog)。
    *   編譯日誌將存於 `logs/compile_icarus.log`。
    *   模擬輸出將存於 `logs/simulation_icarus.log`。
    *   如果測試平台配置正確，波形檔案 (VCD) 將存於 `output/fir_retiming.vcd`。

### 使用 Makefile

1.  開啟一個支援 `make` 的終端機 (如 Git Bash, MinGW, MSYS2, 或 Linux/macOS 終端機)。
2.  導航到專案根目錄。
3.  常用指令：
    *   `make sim`: 使用 Icarus Verilog 編譯並執行模擬。
    *   `make wave`: 同 `make sim`，並嘗試使用 GTKWave 開啟波形 (需確保測試平台生成 `fir_retiming.vcd`)。
    *   `make modelsim`: 執行 ModelSim 模擬 (需已設定 ModelSim 環境並擁有 `simulation/modelsim.do` 腳本)。
    *   `make quartus`: 執行 Quartus Prime Tcl 腳本以設定專案 (需已安裝 Quartus Prime 並設定好環境變數)。
    *   `make clean`: 清理模擬和編譯產生的檔案。
    *   `make help`: 顯示可用的 `make` 指令。

## 合成與時序分析 (Intel Quartus Prime)

1.  **使用 Tcl 腳本自動設定 (推薦):**
    *   確保 Quartus Prime 的命令列工具 (`quartus_sh`) 在您的系統 PATH 中。
    *   在終端機中，於專案根目錄下執行: `make quartus` 或 `cd scripts && quartus_sh -t quartus_project_setup.tcl`。
    *   這將在 `quartus_project` (或 Tcl 腳本中定義的名稱) 資料夾中創建一個 Quartus 專案。
2.  **手動設定:**
    *   請參考 `docs/design_spec.md` 或先前對話中提供的詳細手動設定步驟。
3.  **執行合成與分析:**
    *   開啟 Quartus Prime 專案。
    *   將 `fir_original.v` 或 `fir_retimed.v` 設為頂層模組。
    *   加入 `src` 中的 Verilog 檔案和 `constraints/timing_constraints.sdc`。
    *   執行 "Analysis & Synthesis"，然後可以執行 "Timing Analyzer" 來查看 Fmax 和關鍵路徑。
    *   比較 `fir_original` 和 `fir_retimed` 的合成結果，以評估 Retiming 的效果。

## 學習重點

- **FIR 濾波器原理:** 理解直接型 FIR 濾波器的基本結構和運作方式。
- **Retiming 技術:** 學習如何透過在組合邏輯路徑中插入暫存器 (流水線化) 來優化數位電路的時序性能。
- **效能取捨:** 認識到 Retiming 可以在提高工作頻率的同時，也會帶來延遲增加和資源消耗增加的代價。
- **Verilog 設計與驗證:** 練習使用 Verilog 進行 RTL 設計和編寫測試平台進行功能驗證。
- **FPGA 設計流程:** 了解從 RTL 設計、模擬驗證到 FPGA 合成和時序分析的基本流程。

## 預期結果

透過 Retiming，`fir_retimed` 設計相較於 `fir_original` 設計，預期能達到更高的最大工作頻率 (Fmax)，但其輸出延遲會增加，並且會使用更多的暫存器資源。測試平台的模擬結果應顯示兩個設計在功能上是等效的 (即在考慮到額外延遲後，輸出序列相同)。 