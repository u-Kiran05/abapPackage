REPORT ZR_EPAY_PDF.

TYPE-POOLS: sfp.

PARAMETERS: p_empid TYPE pernr_d OBLIGATORY.

DATA: lv_form        TYPE funcname VALUE 'ZAF_EPAY',
      lv_fm_name     TYPE funcname,
      lv_out         TYPE sfpoutputparams,
      lv_doc         TYPE sfpdocparams,
      lv_formoutput  TYPE fpformoutput,
      lv_filename    TYPE string,
      lv_path        TYPE string,
      lv_fullpath    TYPE string.

" Output data structures
DATA: lt_header TYPE zhcm_epay_s,
      lt_items  TYPE zhcm_epay_i_t.

" Alpha conversion
CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
  EXPORTING input  = p_empid
  IMPORTING output = p_empid.

" Get Adobe form FM name
CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
  EXPORTING
    i_name     = lv_form
  IMPORTING
    e_funcname = lv_fm_name
  EXCEPTIONS
    OTHERS     = 1.
IF sy-subrc <> 0.
  MESSAGE 'Adobe Form not found' TYPE 'E'.
ENDIF.

lv_out-nodialog = abap_true.
lv_out-preview  = abap_true.
lv_out-getpdf   = abap_true.

CALL FUNCTION 'FP_JOB_OPEN'
  CHANGING
    ie_outputparams = lv_out
  EXCEPTIONS
    OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'FP_JOB_OPEN failed' TYPE 'E'.
ENDIF.

CALL FUNCTION lv_fm_name
  EXPORTING
    /1bcdwb/docparams = lv_doc
    i_emp_id          = p_empid
  IMPORTING
    /1bcdwb/formoutput = lv_formoutput
  CHANGING
    et_header          = lt_header
    et_items           = lt_items
  EXCEPTIONS
    OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'Form generation failed' TYPE 'E'.
ENDIF.

CALL FUNCTION 'FP_JOB_CLOSE'
  EXCEPTIONS
    OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'FP_JOB_CLOSE failed' TYPE 'E'.
ENDIF.

IF lv_formoutput-pdf IS NOT INITIAL.
  DATA: it_pdf       TYPE STANDARD TABLE OF x255,
        lv_len       TYPE i,
        lv_b64       TYPE string.

  " Convert PDF to binary
  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lv_formoutput-pdf
    IMPORTING
      output_length = lv_len
    TABLES
      binary_tab    = it_pdf.

  " Convert PDF XSTRING to Base64 string
  CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
    EXPORTING
      input  = lv_formoutput-pdf
    IMPORTING
      output = lv_b64.

  " Export values into memory for function module retrieval
  EXPORT lv_formoutput TO MEMORY ID 'C_MEMORY'.
  EXPORT lv_b64 TO MEMORY ID 'C_B64_STRING'.

  " Optional: Allow user to download manually
  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_extension = 'pdf'
      default_file_name = |Payslip_{ p_empid }.pdf|
      file_filter       = 'PDF Files (*.pdf)|*.pdf|'
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
    EXCEPTIONS
      OTHERS            = 1.

  IF sy-subrc = 0 AND lv_fullpath IS NOT INITIAL.
    CALL FUNCTION 'GUI_DOWNLOAD'
      EXPORTING
        filename = lv_fullpath
        filetype = 'BIN'
      TABLES
        data_tab = it_pdf.
    MESSAGE |PDF saved to { lv_fullpath }| TYPE 'S'.
  ELSE.
    MESSAGE 'Download skipped or cancelled' TYPE 'I'.
  ENDIF.
ENDIF.
