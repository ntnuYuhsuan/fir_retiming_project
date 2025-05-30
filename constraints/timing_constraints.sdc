# 時序約束檔案: timing_constraints.sdc

# 1. 時脈定義
# 假設我們的目標時脈頻率是 100 MHz (週期為 10 ns)
# 將 'clk' 替換成您設計中實際的時脈埠名稱
create_clock -name clk_pin -period 10.000 [get_ports {clk}]

# 2. 時脈不確定性 (Clock Uncertainty)
# 通常用於考慮時脈抖動 (jitter) 和偏移 (skew)
# 數值取決於您的時脈源和電路板設計，這裡給一個範例值
set_clock_uncertainty -setup 0.250 [get_clocks {clk_pin}]
set_clock_uncertainty -hold 0.150 [get_clocks {clk_pin}]

# 3. 輸入延遲 (Input Delay)
# 這些值表示外部訊號到達 FPGA 輸入埠相對於時脈邊緣的時間。
# 這些值需要根據您的系統級設計來確定 (例如，來自外部 ADC 或其他晶片)。
# 假設輸入數據在時脈邊緣前 2ns 到達，並在時脈邊緣後 0.5ns 保持穩定。
# 將 'data_in[*]' 'reset_n' 'ena' 替換成實際的輸入埠名稱
# Max delay 是針對 setup check, min delay 是針對 hold check
set_input_delay -clock clk_pin -max 2.000 [get_ports {data_in[*]}]
set_input_delay -clock clk_pin -min 0.500 [get_ports {data_in[*]}]
set_input_delay -clock clk_pin -max 2.000 [get_ports {reset_n}]
set_input_delay -clock clk_pin -min 0.500 [get_ports {reset_n}]
set_input_delay -clock clk_pin -max 2.000 [get_ports {ena}]
set_input_delay -clock clk_pin -min 0.500 [get_ports {ena}]

# 4. 輸出延遲 (Output Delay)
# 這些值表示 FPGA 輸出埠的訊號需要在時脈邊緣後多久內被外部元件捕獲。
# Max delay 是針對 setup check (外部元件的 tSU), min delay 是針對 hold check (外部元件的 tH)
# 假設外部元件在時脈邊緣後需要數據最晚在 2.5ns 準備好，最早在 -0.5ns (即時脈邊緣前0.5ns) 變化。
# 將 'data_out[*]' 替換成實際的輸出埠名稱
set_output_delay -clock clk_pin -max 2.500 [get_ports {data_out[*]}]
set_output_delay -clock clk_pin -min -0.500 [get_ports {data_out[*]}]

# 5. (可選) 設定偽路徑 (False Paths)
# 如果設計中有一些路徑在功能上是存在的，但不需要進行時序分析 (例如，重置路徑或測試邏輯)，
# 可以將它們設定為偽路徑。
# 例如，如果 reset_n 是非同步重置，其路徑可能不需要嚴格的時序分析，
# 但通常更好的做法是確保非同步重置路徑有適當的同步器。
# set_false_path -from [get_ports {reset_n}] -to [all_registers]

# 6. (可選) 設定多週期路徑 (Multicycle Paths)
# 如果設計中有一些路徑已知需要多個時脈週期才能完成，可以在此設定。
# 對於我們的 FIR 設計，如果沒有明確的多週期操作，則不需要。
# set_multicycle_path -setup -from [get_registers {src_reg}] -to [get_registers {dest_reg}] 2
# set_multicycle_path -hold  -from [get_registers {src_reg}] -to [get_registers {dest_reg}] 1

# 7. 設計環境約束 (Operating Conditions)
# 這些通常由 FPGA 工具根據選擇的元件型號自動設定，但有時可以指定。
# set_operating_conditions -speed_grade <grade> -voltage <voltage> -temperature <temperature>

# 8. 時脈分組 (Clock Groups) - 如果有多個不相關的時脈域
# set_clock_groups -asynchronous -group [get_clocks clk1] -group [get_clocks clk2]

# 請注意：
# - 上述的埠名稱 (clk, data_in[*], data_out[*], reset_n, ena) 必須與您 Verilog 模組中的頂層埠名稱完全匹配。
# - 延遲值 (2.000, 0.500 等) 是範例值，您需要根據您的具體設計和系統環境來調整。
# - 這個 SDC 檔案可以同時用於 fir_original 和 fir_retimed 設計，因為它們的頂層接口是相同的。
#   合成工具會根據各自的內部邏輯和這個 SDC 來進行優化和報告。 