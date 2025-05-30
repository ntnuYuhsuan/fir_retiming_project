# 設計規格說明

## 1. 專案目標

本專案旨在設計並實現一個可參數化的 FIR (Finite Impulse Response) 數位濾波器，並應用 Retiming 技術來優化其時序性能，目標是提高最大工作頻率。我們將比較原始設計和 Retiming 後設計的性能。

## 2. FIR 濾波器規格

*   **類型：** 可參數化的 FIR 濾波器。
    *   **參數 N_TAPS:** 濾波器階數 (抽頭數量)。預設為 4-tap (可根據需求調整)。
    *   **參數 DATA_WIDTH:** 輸入數據位元寬度。預設為 18 位元。
    *   **參數 COEFF_WIDTH:** 濾波器係數位元寬度。預設為 18 位元。
    *   **參數 OUTPUT_WIDTH:** 輸出數據位元寬度。計算公式：`(DATA_WIDTH + COEFF_WIDTH) + ceil(log2(N_TAPS))`
*   **輸入訊號：**
    *   `clk`: 時脈訊號
    *   `reset_n`: 非同步低電位重置訊號
    *   `ena`: 致能訊號
    *   `data_in`: 輸入數據 (DATA_WIDTH 位元)
*   **輸出訊號：**
    *   `data_out`: 濾波後的輸出數據 (OUTPUT_WIDTH 位元)
*   **濾波器係數：**
    *   係數將作為參數或內部 `localparam` 在 Verilog 模組中定義。

## 3. 原始 FIR 設計 (`src/fir_original.v`)

*   將採用直接形式 (Direct Form I) 或其變體來實現。
*   結構：一系列延遲元件、乘法器和一個累加樹。
*   關鍵路徑：預期是通過乘法器和累加樹的路徑。

## 4. Retiming 優化設計 (`src/fir_retimed.v`)

*   **目標：** 縮短 `fir_original.v` 中的關鍵路徑。
*   **策略：**
    1.  **流水線化 MAC 操作：** 在乘法器和加法器之間插入寄存器。
    2.  **結構轉換/寄存器重分佈：** 考慮使用類似轉置形式的結構。
*   **實現方式：**
    *   分析 `fir_original.v` 的關鍵路徑。
    *   手動修改 Verilog 程式碼，將寄存器插入到適當位置。
    *   Retiming 後的設計會引入額外的輸出延遲 (latency)。

## 5. Cyclone V DSP Block 架構參考

Cyclone V DSP Block 的架構（如輸入寄存器、系統暫存器、前置加法器、乘法器、累加器、輸出寄存器）為 Retiming 提供了指導思想，即在關鍵計算單元周圍策略性地放置寄存器以實現流水線。

## 6. 驗證 (`src/fir_retiming_tb.v`)

*   創建一個測試平台來驗證原始 FIR 和 Retiming 後 FIR 的功能正確性。
*   測試平台應包含時脈/重置產生、輸入激勵、DUT 實例化、與黃金參考模型比較，並考慮 Retiming 引入的延遲。

## 7. 時序約束 (`constraints/timing_constraints.sdc`)

*   為 `fir_original.v` 和 `fir_retimed.v` 分別創建 SDC 檔案。
*   包含時脈定義、輸入/輸出延遲等。

## 8. 腳本 (`scripts/quartus_project_setup.tcl`, `simulation/modelsim.do`)

*   `quartus_project_setup.tcl`: 自動化 Quartus Prime 專案創建和設定。
*   `modelsim.do`: ModelSim 模擬腳本。 