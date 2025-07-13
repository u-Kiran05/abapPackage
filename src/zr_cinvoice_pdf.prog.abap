*&---------------------------------------------------------------------*
*& Report ZR_CINVOICE_PDF
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZR_CINVOICE_PDF.


TYPE-POOLS: sfp.

PARAMETERS: p_kunag TYPE kunag OBLIGATORY,
            p_vbeln TYPE vbeln OBLIGATORY MATCHCODE OBJECT zvbrk_vbeln.

DATA: lv_form        TYPE funcname VALUE 'ZAF_CINVOICE',
      lv_fm_name     TYPE funcname,
      lv_out         TYPE sfpoutputparams,
      lv_doc         TYPE sfpdocparams,
      lv_formoutput  TYPE fpformoutput,
      lv_cust_name   TYPE name1,
      lv_filename    TYPE string,
      lv_path        TYPE string,
      lv_fullpath    TYPE string.
DATA: lt_header TYPE zsd_cinvoice_t.
" Updated header and items using your structures
DATA: t_header TYPE zsd_cinvoice_s,
      t_items  TYPE zsd_cinvoice_i_t.

" Fetch header from VBRK
SELECT SINGLE vbeln fkdat netwr waerk erdat bukrs
  INTO CORRESPONDING FIELDS OF t_header
  FROM vbrk
  WHERE vbeln = p_vbeln
    AND kunag = p_kunag
    AND fksto = ''.

IF sy-subrc <> 0.
  MESSAGE 'Invalid VBELN for the given Customer or Invoice is cancelled' TYPE 'E'.
ENDIF.

" Fetch customer name
SELECT SINGLE name1 INTO lv_cust_name FROM kna1 WHERE kunnr = p_kunag.

" Fetch items from VBRP using ZSD_CINVOICE_I_S structure
SELECT vbeln posnr matnr arktx fkimg vrkme netwr
  INTO CORRESPONDING FIELDS OF TABLE t_items
  FROM vbrp
  WHERE vbeln = p_vbeln.

IF sy-subrc <> 0 OR t_items IS INITIAL.
  MESSAGE 'No item data found for this invoice' TYPE 'E'.
ENDIF.

* Adobe Form Module
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

lv_doc-dynamic = abap_true.
APPEND t_header TO lt_header.
* Call Adobe Form using structures
CALL FUNCTION lv_fm_name
  EXPORTING
    /1bcdwb/docparams = lv_doc
    i_customer_id      = p_kunag         " Required input for ZIF_CINVOICE
    i_invoice_id       = p_vbeln         " Required input for ZIF_CINVOICE
  IMPORTING
    /1bcdwb/formoutput = lv_formoutput
  TABLES
    t_header           = lt_header " Wrap into internal table if necessary
    t_items            = t_items
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
  EXPORT lv_formoutput TO MEMORY ID 'C_MEMORY'.

  DATA: it_pdf TYPE STANDARD TABLE OF x255,
        lv_len TYPE i.

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING
      buffer        = lv_formoutput-pdf
    IMPORTING
      output_length = lv_len
    TABLES
      binary_tab    = it_pdf.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_extension = 'pdf'
      default_file_name = |Invoice_{ t_header-vbeln }.pdf|
      file_filter       = 'PDF Files (*.pdf)|*.pdf|'
    CHANGING
      filename          = lv_filename
      path              = lv_path
      fullpath          = lv_fullpath
    EXCEPTIONS
      OTHERS            = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Download cancelled by user' TYPE 'I'.
    RETURN.
  ENDIF.

  CALL FUNCTION 'GUI_DOWNLOAD'
    EXPORTING
      filename = lv_fullpath
      filetype = 'BIN'
    TABLES
      data_tab = it_pdf.

  MESSAGE |PDF saved to { lv_fullpath }| TYPE 'S'.
ENDIF.
