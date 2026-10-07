// axis_doubler.v
// Найпростіший можливий AXI4-Stream акселератор: множить кожне
// вхідне 16-бітне значення на 2. Правильно обробляє backpressure
// (TREADY) з обох боків -- жодних припущень "приймач завжди готовий".

module axis_doubler #(
    parameter DATA_WIDTH = 16
) (
    input  wire                        aclk,
    input  wire                        aresetn,

    // ---- Slave side (вхід потоку) ----
    input  wire [DATA_WIDTH-1:0]       s_axis_tdata,
    input  wire                        s_axis_tvalid,
    output wire                        s_axis_tready,
    input  wire                        s_axis_tlast,

    // ---- Master side (вихід потоку) ----
    output reg  [DATA_WIDTH-1:0]       m_axis_tdata,
    output reg                         m_axis_tvalid,
    input  wire                        m_axis_tready,
    output reg                         m_axis_tlast
);

    // Простий, однотактовий конвеєр: приймаємо слово, наступного
    // такту видаємо подвоєне значення. slave готовий приймати новий
    // вхід, лише коли master-вихід або порожній, або саме
    // "звільняється" цього такту (m_axis_tready==1).
    assign s_axis_tready = !m_axis_tvalid || m_axis_tready;

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_tvalid <= 1'b0;
            m_axis_tdata  <= 0;
            m_axis_tlast  <= 1'b0;
        end else begin
            if (s_axis_tready && s_axis_tvalid) begin
                m_axis_tdata  <= s_axis_tdata * 2;
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= s_axis_tlast;
            end else if (m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
            end
        end
    end

endmodule
