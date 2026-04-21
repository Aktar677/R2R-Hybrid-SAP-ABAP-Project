"""
R2R (Record-to-Report) Financial Close Dashboard
=================================================
SIMULATION LAYER — Python/Streamlit
This file simulates the R2R process for demonstration purposes.
The actual production implementation is in ABAP (see src/abap/).

Author: [Your Name] | Roll No: [Your Roll No] | Batch: SAP ABAP
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, date
import json
import os

st.set_page_config(
    page_title="R2R Financial Close Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ─── Custom CSS ───────────────────────────────────────────────
st.markdown("""
<style>
    .main { background-color: #f8f9fa; }
    .metric-card {
        background: white;
        border-radius: 12px;
        padding: 1.2rem;
        border-left: 4px solid #0070f3;
        box-shadow: 0 2px 8px rgba(0,0,0,0.08);
    }
    .status-open    { color: #dc3545; font-weight: 600; }
    .status-done    { color: #28a745; font-weight: 600; }
    .status-pending { color: #ffc107; font-weight: 600; }
    .header-banner {
        background: linear-gradient(135deg, #003087 0%, #0070f3 100%);
        color: white;
        padding: 1.5rem 2rem;
        border-radius: 12px;
        margin-bottom: 1.5rem;
    }
    .note-box {
        background: #fff3cd;
        border: 1px solid #ffc107;
        border-radius: 8px;
        padding: 0.8rem 1rem;
        margin-bottom: 1rem;
        font-size: 0.85rem;
    }
</style>
""", unsafe_allow_html=True)

# ─── Load Data ────────────────────────────────────────────────
DATA_PATH = os.path.join(os.path.dirname(__file__), "../../data/r2r_data.json")

@st.cache_data
def load_data():
    with open(DATA_PATH, "r") as f:
        return json.load(f)

data = load_data()

# ─── Sidebar ─────────────────────────────────────────────────
with st.sidebar:
    st.image("https://upload.wikimedia.org/wikipedia/commons/thumb/5/59/SAP_2011_logo.svg/200px-SAP_2011_logo.svg.png", width=120)
    st.markdown("### R2R Close System")
    st.markdown("---")
    company   = st.selectbox("Company Code", ["1000 – ABC Ltd", "2000 – XYZ Corp"])
    period    = st.selectbox("Fiscal Period", ["03/2026 (March)", "02/2026 (February)", "01/2026 (January)"])
    ledger    = st.selectbox("Ledger", ["0L – Leading Ledger", "2L – Local GAAP"])
    st.markdown("---")
    st.markdown("**SAP Equivalent T-Codes:**")
    st.code("ZR2R_TB  – Trial Balance\nZR2R_JE  – JE Validation\nZR2R_RC  – Reconciliation\nZR2R_FS  – Fin Statements\nZR2R_CL  – Close Tracker")
    st.markdown("---")
    st.caption("⚠️ This is a simulation.\nActual deployment: SAP ABAP")

# ─── Header ──────────────────────────────────────────────────
st.markdown("""
<div class="header-banner">
    <h2 style="margin:0;font-size:1.6rem;">📊 Record-to-Report — Month-End Close Dashboard</h2>
    <p style="margin:0.3rem 0 0;opacity:0.85;">Financial Close Automation | SAP ABAP Capstone Project</p>
</div>
""", unsafe_allow_html=True)

st.markdown("""
<div class="note-box">
    <strong>📌 Project Note:</strong> This Python/Streamlit layer simulates the R2R process for visual demonstration.
    The production ABAP implementation (ZR2R_* programs) runs directly in the SAP FI system using tables BKPF, BSEG, FAGLFLEXT, SKA1, BSIS, BSAS.
    See <code>src/abap/</code> for full ABAP source code.
</div>
""", unsafe_allow_html=True)

# ─── KPI Row ─────────────────────────────────────────────────
col1, col2, col3, col4, col5 = st.columns(5)
kpis = data["kpis"]
col1.metric("Total Entries",    f"{kpis['total_entries']:,}",   f"+{kpis['entries_delta']} vs prior")
col2.metric("Total Debits",     f"₹{kpis['total_debits']:,.0f}L",  "")
col3.metric("Total Credits",    f"₹{kpis['total_credits']:,.0f}L", "")
col4.metric("Unreconciled",     kpis['unreconciled'],           delta_color="inverse")
col5.metric("Close Progress",   f"{kpis['close_pct']}%",        "")

st.markdown("---")

# ─── Tabs ─────────────────────────────────────────────────────
tab1, tab2, tab3, tab4, tab5 = st.tabs([
    "📋 Close Checklist",
    "⚖️ Trial Balance",
    "🔍 JE Validation",
    "🔄 Reconciliation",
    "📈 Financial Statements"
])

# ═══════════════════════════════════════════════════════════════
# TAB 1 – Close Checklist (Z-Table: ZCLOSE_CHECKLIST)
# ═══════════════════════════════════════════════════════════════
with tab1:
    st.subheader("Month-End Close Task Tracker")
    st.caption("SAP equivalent: Z-table ZCLOSE_CHECKLIST | T-Code: ZR2R_CL")

    tasks = pd.DataFrame(data["close_checklist"])
    tasks["Status"] = tasks["status"].map({"C": "✅ Complete", "O": "🔴 Open", "P": "🟡 In Progress"})

    done    = len(tasks[tasks["status"] == "C"])
    total   = len(tasks)
    pct     = int(done / total * 100)
    st.progress(pct / 100, text=f"Close Progress: {pct}%  ({done}/{total} tasks complete)")
    st.markdown("<br>", unsafe_allow_html=True)

    display_cols = ["task_id", "task_description", "owner", "due_date", "Status", "completed_by"]
    st.dataframe(
        tasks[display_cols].rename(columns={
            "task_id": "Task ID", "task_description": "Description",
            "owner": "Owner", "due_date": "Due Date", "completed_by": "Completed By"
        }),
        use_container_width=True, hide_index=True
    )

    fig_pie = px.pie(
        tasks, names="Status", title="Task Status Distribution",
        color="Status",
        color_discrete_map={"✅ Complete": "#28a745", "🔴 Open": "#dc3545", "🟡 In Progress": "#ffc107"}
    )
    fig_pie.update_layout(height=300)
    st.plotly_chart(fig_pie, use_container_width=True)

# ═══════════════════════════════════════════════════════════════
# TAB 2 – Trial Balance (FAGLFLEXT)
# ═══════════════════════════════════════════════════════════════
with tab2:
    st.subheader("Trial Balance Report")
    st.caption("SAP equivalent: FAGLFLEXT, SKA1 | T-Code: ZR2R_TB")

    tb = pd.DataFrame(data["trial_balance"])
    tb["Debit (₹L)"]  = tb["debit"].apply(lambda x: f"₹{x:,.2f}")
    tb["Credit (₹L)"] = tb["credit"].apply(lambda x: f"₹{x:,.2f}")
    tb["Balance (₹L)"] = tb["balance"].apply(lambda x: f"₹{x:,.2f}")

    total_dr = tb["debit"].sum()
    total_cr = tb["credit"].sum()
    balanced = "✅ BALANCED" if abs(total_dr - total_cr) < 0.01 else "❌ NOT BALANCED"

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Debits",  f"₹{total_dr:,.2f}L")
    c2.metric("Total Credits", f"₹{total_cr:,.2f}L")
    c3.metric("Check", balanced)

    filter_type = st.selectbox("Filter by Account Type", ["All", "Asset", "Liability", "Revenue", "Expense", "Equity"])
    if filter_type != "All":
        tb_view = tb[tb["account_type"] == filter_type]
    else:
        tb_view = tb

    st.dataframe(
        tb_view[["account_code", "account_name", "account_type", "Debit (₹L)", "Credit (₹L)", "Balance (₹L)"]].rename(columns={
            "account_code": "Acct Code", "account_name": "Account Name", "account_type": "Type"
        }),
        use_container_width=True, hide_index=True
    )

    fig_tb = px.bar(
        tb, x="account_name", y=["debit","credit"],
        title="Debits vs Credits by Account", barmode="group",
        labels={"value": "Amount (₹L)", "account_name": "Account"},
        color_discrete_map={"debit": "#0070f3", "credit": "#ff6b6b"}
    )
    fig_tb.update_layout(height=400, xaxis_tickangle=-45)
    st.plotly_chart(fig_tb, use_container_width=True)

# ═══════════════════════════════════════════════════════════════
# TAB 3 – Journal Entry Validation (BKPF + BSEG)
# ═══════════════════════════════════════════════════════════════
with tab3:
    st.subheader("Journal Entry Validation")
    st.caption("SAP equivalent: BKPF + BSEG | T-Code: ZR2R_JE")

    je = pd.DataFrame(data["journal_entries"])
    je["Valid"] = je.apply(lambda r: "✅ Valid" if abs(r["debit"] - r["credit"]) < 0.01 else "❌ Invalid", axis=1)

    valid_count   = len(je[je["Valid"] == "✅ Valid"])
    invalid_count = len(je[je["Valid"] == "❌ Invalid"])

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Entries", len(je))
    c2.metric("Valid", valid_count)
    c3.metric("Invalid / Flag", invalid_count)

    # Checkbox filter
    show_invalid = st.checkbox("Show only invalid/flagged entries")
    je_view = je[je["Valid"] == "❌ Invalid"] if show_invalid else je

    st.dataframe(
        je_view[["doc_number","posting_date","account","description","debit","credit","Valid"]].rename(columns={
            "doc_number":"Doc No","posting_date":"Date","account":"Account",
            "description":"Description","debit":"Debit (₹L)","credit":"Credit (₹L)"
        }),
        use_container_width=True, hide_index=True
    )

    # --- FIXED GRAPH ---
    je["posting_date"] = pd.to_datetime(je["posting_date"])

    daily = je.groupby(je["posting_date"].dt.date)[["debit","credit"]].sum().reset_index()

    fig_je = px.line(
        daily,
        x="posting_date",
        y=["debit", "credit"],
        title="Daily Journal Entry Trend",
        labels={"value": "Amount (₹L)"}
    )

    st.plotly_chart(fig_je, use_container_width=True)
    

# ═══════════════════════════════════════════════════════════════
# TAB 4 – Reconciliation (BSIS vs BSAS)
# ═══════════════════════════════════════════════════════════════
with tab4:
    st.subheader("Account Reconciliation — Open vs Cleared Items")
    st.caption("SAP equivalent: BSIS (open) vs BSAS (cleared) | T-Code: ZR2R_RC")

    recon = pd.DataFrame(data["reconciliation"])
    open_items    = recon[recon["status"] == "Open"]
    cleared_items = recon[recon["status"] == "Cleared"]

    c1, c2, c3 = st.columns(3)
    c1.metric("Open Items",    len(open_items),    delta_color="inverse")
    c2.metric("Cleared Items", len(cleared_items))
    c3.metric("Open Amount",   f"₹{open_items['amount'].sum():,.2f}L", delta_color="inverse")

    st.markdown("#### Open (Unreconciled) Items")
    st.dataframe(
        open_items[["doc_number","account","account_name","amount","due_date","aging_days"]].rename(columns={
            "doc_number":"Doc No","account":"Account","account_name":"Account Name",
            "amount":"Amount (₹L)","due_date":"Due Date","aging_days":"Aging (Days)"
        }),
        use_container_width=True, hide_index=True
    )

    aging_bins = pd.cut(open_items["aging_days"],
                        bins=[0,30,60,90,180,999],
                        labels=["0-30","31-60","61-90","91-180","180+"])
    aging_summary = open_items.groupby(aging_bins, observed=True)["amount"].sum().reset_index()
    aging_summary.columns = ["Aging Bucket", "Amount"]
    fig_aging = px.bar(aging_summary, x="Aging Bucket", y="Amount",
                       title="Open Items Aging Analysis",
                       color="Aging Bucket",
                       color_discrete_sequence=["#28a745","#ffc107","#fd7e14","#dc3545","#721c24"])
    st.plotly_chart(fig_aging, use_container_width=True)

# ═══════════════════════════════════════════════════════════════
# TAB 5 – Financial Statements
# ═══════════════════════════════════════════════════════════════
with tab5:
    st.subheader("Financial Statements — P&L and Balance Sheet")
    st.caption("SAP equivalent: FAGLFLEXT grouped by account type | T-Code: ZR2R_FS")

    fs = data["financial_statements"]

    col_pl, col_bs = st.columns(2)

    with col_pl:
        st.markdown("### Profit & Loss Statement")
        st.markdown(f"**Period:** {period}")
        pl = pd.DataFrame(fs["pl"])
        for _, row in pl.iterrows():
            if row["is_total"]:
                st.markdown(f"---")
                st.markdown(f"**{row['label']}**: ₹{row['amount']:,.2f}L")
            else:
                st.markdown(f"&nbsp;&nbsp;{row['label']}: ₹{row['amount']:,.2f}L")

        revenue   = sum(r["amount"] for r in fs["pl"] if r["category"] == "Revenue")
        expenses  = sum(r["amount"] for r in fs["pl"] if r["category"] == "Expense")
        net_profit = revenue - expenses
        color = "#28a745" if net_profit >= 0 else "#dc3545"
        st.markdown(f"<h4 style='color:{color}'>Net Profit: ₹{net_profit:,.2f}L</h4>", unsafe_allow_html=True)

        fig_pl = px.bar(
            pd.DataFrame([r for r in fs["pl"] if not r["is_total"]]),
            x="label", y="amount", color="category",
            title="Revenue vs Expenses",
            color_discrete_map={"Revenue": "#28a745", "Expense": "#dc3545"}
        )
        fig_pl.update_layout(height=300, xaxis_tickangle=-30)
        st.plotly_chart(fig_pl, use_container_width=True)

    with col_bs:
        st.markdown("### Balance Sheet")
        bs = pd.DataFrame(fs["bs"])
        for _, row in bs.iterrows():
            if row["is_total"]:
                st.markdown(f"---")
                st.markdown(f"**{row['label']}**: ₹{row['amount']:,.2f}L")
            else:
                st.markdown(f"&nbsp;&nbsp;{row['label']}: ₹{row['amount']:,.2f}L")

        total_assets = sum(r["amount"] for r in fs["bs"] if r["category"] == "Asset")
        total_liab_eq = sum(r["amount"] for r in fs["bs"] if r["category"] in ["Liability","Equity"])
        check = "✅ Balanced" if abs(total_assets - total_liab_eq) < 0.01 else "❌ Not Balanced"
        st.metric("Balance Check", check)

        fig_bs = px.pie(
            pd.DataFrame([r for r in fs["bs"] if not r["is_total"]]),
            values="amount", names="label",
            title="Balance Sheet Composition"
        )
        fig_bs.update_layout(height=300)
        st.plotly_chart(fig_bs, use_container_width=True)

st.markdown("---")
st.caption("R2R Capstone Project | SAP ABAP Batch | Simulation Layer — Actual ABAP code in src/abap/")
