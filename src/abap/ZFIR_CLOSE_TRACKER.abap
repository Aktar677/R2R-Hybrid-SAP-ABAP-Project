*&---------------------------------------------------------------------*
*& Program      : ZFIR_CLOSE_TRACKER
*& Title        : Month-End Close Task Tracker
*& T-Code       : ZR2R_CL
*& Z-Table      : ZCLOSE_CHECKLIST
*& Author       : [Your Name] | Roll No: [Roll No] | Batch: SAP ABAP
*&
*& SETUP REQUIRED:
*& 1. Create Z-table ZCLOSE_CHECKLIST in SE11 with fields below
*& 2. Create data elements: ZFIR_PERIOD, ZFIR_TASKID, ZFIR_STATUS
*& 3. Register T-Code ZR2R_CL in SE93
*&---------------------------------------------------------------------*
*&
*& Z-TABLE: ZCLOSE_CHECKLIST
*& ┌─────────────────┬──────────┬──────────────────────────────────────┐
*& │ Field Name      │ Type     │ Description                          │
*& ├─────────────────┼──────────┼──────────────────────────────────────┤
*& │ MANDT           │ CLNT(3)  │ Client (Key)                         │
*& │ CLOSE_PERIOD    │ NUMC(6)  │ Period YYYYMM (Key)                  │
*& │ BUKRS           │ BUKRS    │ Company Code (Key)                   │
*& │ TASK_ID         │ CHAR(5)  │ Task ID e.g. T001 (Key)              │
*& │ TASK_DESC       │ CHAR(80) │ Task description                     │
*& │ TASK_OWNER      │ CHAR(30) │ Responsible team                     │
*& │ DUE_DATE        │ DATS     │ Task due date                        │
*& │ STATUS          │ CHAR(1)  │ O=Open, P=In Progress, C=Complete   │
*& │ PRIORITY        │ CHAR(1)  │ H=High, M=Medium, L=Low             │
*& │ COMPLETED_BY    │ UNAME    │ SAP User who completed               │
*& │ COMPLETED_ON    │ DATS     │ Completion date                      │
*& │ REMARKS         │ CHAR(200)│ Free text remarks                    │
*& └─────────────────┴──────────┴──────────────────────────────────────┘
*&
*&---------------------------------------------------------------------*

REPORT zfir_close_tracker.

TABLES: zclose_checklist.

TYPES: BEGIN OF ty_tracker,
         close_period  TYPE numc6,
         bukrs         TYPE bukrs,
         task_id       TYPE char5,
         task_desc     TYPE char80,
         task_owner    TYPE char30,
         due_date      TYPE dats,
         status        TYPE char1,
         status_text   TYPE char15,
         priority      TYPE char1,
         completed_by  TYPE uname,
         completed_on  TYPE dats,
         remarks       TYPE char200,
         color         TYPE c LENGTH 4,
       END OF ty_tracker.

DATA: gt_tracker TYPE TABLE OF ty_tracker,
      gs_tracker TYPE ty_tracker.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_bukrs  FOR zclose_checklist-bukrs  OBLIGATORY.
  PARAMETERS:     p_period TYPE numc6 OBLIGATORY.    " YYYYMM e.g. 202603
  PARAMETERS:     p_status TYPE char1 AS LISTBOX VISIBLE LENGTH 20.
SELECTION-SCREEN END OF BLOCK b1.

INITIALIZATION.
  TEXT-001 = 'Close Task Filter'.
  " Default to current year+month
  p_period = |{ sy-datum(4) }{ sy-datum+4(2) }|.

  " Populate status dropdown
  DATA: lt_status TYPE vrm_values,
        ls_status TYPE vrm_value.
  ls_status-key = ' '. ls_status-text = 'All Statuses'. APPEND ls_status TO lt_status.
  ls_status-key = 'O'. ls_status-text = 'Open'.         APPEND ls_status TO lt_status.
  ls_status-key = 'P'. ls_status-text = 'In Progress'.  APPEND ls_status TO lt_status.
  ls_status-key = 'C'. ls_status-text = 'Complete'.     APPEND ls_status TO lt_status.
  CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_STATUS' TABLES values = lt_status.

*----------------------------------------------------------------------*
START-OF-SELECTION.
*----------------------------------------------------------------------*

  " Fetch from Z-table
  IF p_status = space.
    SELECT * INTO TABLE @DATA(lt_raw)
      FROM zclose_checklist
      WHERE mandt = @sy-mandt
        AND bukrs IN @s_bukrs
        AND close_period = @p_period.
  ELSE.
    SELECT * INTO TABLE @lt_raw
      FROM zclose_checklist
      WHERE mandt = @sy-mandt
        AND bukrs IN @s_bukrs
        AND close_period = @p_period
        AND status = @p_status.
  ENDIF.

  " Build display table with status text + traffic light colors
  LOOP AT lt_raw INTO DATA(ls_raw).
    CLEAR gs_tracker.
    MOVE-CORRESPONDING ls_raw TO gs_tracker.

    gs_tracker-status_text = SWITCH #( ls_raw-status
                                        WHEN 'C' THEN '✅ Complete'
                                        WHEN 'P' THEN '⏳ In Progress'
                                        WHEN 'O' THEN '🔴 Open'
                                        ELSE ls_raw-status ).

    " ALV traffic light coloring
    gs_tracker-color = SWITCH #( ls_raw-status
                                  WHEN 'C' THEN 'C310'   " Green
                                  WHEN 'P' THEN 'C510'   " Yellow
                                  WHEN 'O' THEN 'C610'   " Red
                                  ELSE 'C010' ).

    APPEND gs_tracker TO gt_tracker.
  ENDLOOP.

  " Print summary
  DATA(lv_total)    = lines( gt_tracker ).
  DATA(lv_complete) = REDUCE i( INIT n = 0 FOR w IN gt_tracker WHERE ( status = 'C' ) NEXT n = n + 1 ).
  DATA(lv_pct)      = COND i( WHEN lv_total > 0 THEN ( lv_complete * 100 ) / lv_total ELSE 0 ).

  WRITE: / |Period: { p_period }  |  |Tasks: { lv_total }  |  |Complete: { lv_complete } ({ lv_pct }%)|.
  SKIP.

  " Display ALV
  DATA: lo_alv     TYPE REF TO cl_salv_table,
        lo_display TYPE REF TO cl_salv_display_settings,
        lo_funcs   TYPE REF TO cl_salv_functions_list,
        lx_error   TYPE REF TO cx_salv_msg.

  TRY.
    cl_salv_table=>factory(
      IMPORTING r_salv_table = lo_alv
      CHANGING  t_table      = gt_tracker ).

    lo_display = lo_alv->get_display_settings( ).
    lo_display->set_list_header( |Month-End Close Checklist — { p_period }| ).
    lo_display->set_striped_pattern( abap_true ).

    lo_funcs = lo_alv->get_functions( ).
    lo_funcs->set_all( abap_true ).

    lo_alv->display( ).

  CATCH cx_salv_msg INTO lx_error.
    MESSAGE lx_error TYPE 'E'.
  ENDTRY.
