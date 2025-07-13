*&---------------------------------------------------------------------*
*& Report ZR_VINVOICE_PDF
*&---------------------------------------------------------------------*
*& Generate Vendor Invoice PDF using Adobe Form ZAF_VINVOICE
*&---------------------------------------------------------------------*
REPORT zr_vinvoice_pdf.

TYPE-POOLS: sfp.

PARAMETERS: p_lifnr TYPE lifnr OBLIGATORY,
            p_belnr TYPE belnr_d OBLIGATORY.

DATA: lv_form        TYPE funcname VALUE 'ZAF_VINVOICE',
      lv_fm_name     TYPE funcname,
      lv_out         TYPE sfpoutputparams,
      lv_doc         TYPE sfpdocparams,
      lv_formoutput  TYPE fpformoutput,
      lv_filename    TYPE string,
      lv_path        TYPE string,
      lv_fullpath    TYPE string.

DATA: t_header  TYPE zmm_vinvoice_s,
      lt_header TYPE zmm_vinvoice_t,
      t_items   TYPE zmm_vinvoice_i_t.

CLEAR: t_header, t_items.

" Fetch Header from RBKP
SELECT SINGLE belnr gjahr bukrs lifnr budat bldat rmwwr waers
  INTO CORRESPONDING FIELDS OF t_header
  FROM rbkp
  WHERE belnr = p_belnr
    AND lifnr = p_lifnr.

IF sy-subrc <> 0.
  MESSAGE 'Invalid Invoice Number or Vendor ID' TYPE 'E'.
ENDIF.

" Fetch Items from RSEG
SELECT ebeln, ebelp, matnr, menge, meins, wrbtr ,bstme
  INTO TABLE @DATA(lt_rseg)
  FROM rseg
  WHERE belnr = @p_belnr.

" Populate item details
LOOP AT lt_rseg INTO DATA(ls_rseg).
  DATA(ls_item) = VALUE zmm_vinvoice_i_s(
    ebeln  = ls_rseg-ebeln
    ebelp  = ls_rseg-ebelp
    matnr  = ls_rseg-matnr
    menge  = ls_rseg-menge
    meins  = ls_rseg-meins
    wrbtr  = ls_rseg-wrbtr
    waers  = t_header-waers ).

  " Get material description
  SELECT SINGLE maktx INTO ls_item-maktx
    FROM makt
    WHERE matnr = ls_item-matnr
      AND spras = sy-langu.

  APPEND ls_item TO t_items.
ENDLOOP.

APPEND t_header TO lt_header.

" Generate Function Module Name
CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
  EXPORTING i_name = lv_form
  IMPORTING e_funcname = lv_fm_name
  EXCEPTIONS OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'Adobe Form not found' TYPE 'E'.
ENDIF.

lv_out-nodialog = abap_true.
lv_out-preview  = abap_true.
lv_out-getpdf   = abap_true.

CALL FUNCTION 'FP_JOB_OPEN'
  CHANGING ie_outputparams = lv_out
  EXCEPTIONS OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'FP_JOB_OPEN failed' TYPE 'E'.
ENDIF.

lv_doc-dynamic = abap_true.

CALL FUNCTION lv_fm_name
  EXPORTING
    /1bcdwb/docparams = lv_doc
    i_invoice_id      = p_belnr
    i_vendor_id       = p_lifnr
  IMPORTING
    /1bcdwb/formoutput = lv_formoutput
  TABLES
    t_header           = lt_header
    t_items            = t_items
  EXCEPTIONS
    OTHERS             = 1.
IF sy-subrc <> 0.
  MESSAGE 'Form generation failed' TYPE 'E'.
ENDIF.

CALL FUNCTION 'FP_JOB_CLOSE'
  EXCEPTIONS OTHERS = 1.
IF sy-subrc <> 0.
  MESSAGE 'FP_JOB_CLOSE failed' TYPE 'E'.
ENDIF.

" Download PDF if generated
IF lv_formoutput-pdf IS NOT INITIAL.
  DATA: it_pdf TYPE STANDARD TABLE OF x255,
        lv_len TYPE i.

  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
    EXPORTING buffer = lv_formoutput-pdf
    IMPORTING output_length = lv_len
    TABLES binary_tab = it_pdf.

  CALL METHOD cl_gui_frontend_services=>file_save_dialog
    EXPORTING
      default_extension = 'pdf'
      default_file_name = |VendorInvoice_{ p_belnr }.pdf|
      file_filter       = 'PDF Files (*.pdf)|*.pdf|'
    CHANGING
      filename = lv_filename
      path     = lv_path
      fullpath = lv_fullpath
    EXCEPTIONS OTHERS = 1.

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
