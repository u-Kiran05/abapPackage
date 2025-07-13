class ZCL_ZSEGW_VENDORINVOIC_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_VENDORINVOIC_DPC
  create public .

public section.

  methods /IWBEP/IF_MGW_APPL_SRV_RUNTIME~GET_STREAM
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_VENDORINVOIC_DPC_EXT IMPLEMENTATION.


METHOD /iwbep/if_mgw_appl_srv_runtime~get_stream.

  TYPES: BEGIN OF ty_s_media_resource,
           mime_type TYPE string,
           value     TYPE xstring,
         END OF ty_s_media_resource.

  DATA: lv_funcname      TYPE funcname,
        ls_output        TYPE sfpoutputparams,
        ls_formoutput    TYPE fpformoutput,
        ls_docparams     TYPE sfpdocparams,
        ls_stream        TYPE ty_s_media_resource,
        lv_belnr         TYPE belnr_d,
        lv_lifnr         TYPE lifnr,
        ls_value         TYPE /iwbep/s_mgw_name_value_pair,
        lo_msg_container TYPE REF TO /iwbep/if_message_container,
        lv_msg_text      TYPE bapi_msg.

  CONSTANTS: lc_form_name TYPE fpname VALUE 'ZAF_VINVOICE'.

  DATA: lt_header TYPE zmm_vinvoice_t,
        t_header  TYPE zmm_vinvoice_s,
        t_items   TYPE zmm_vinvoice_i_t.

  LOOP AT it_key_tab INTO ls_value.
    CASE to_upper( ls_value-name ).
      WHEN 'BELNR'. lv_belnr = ls_value-value.
      WHEN 'LIFNR'. lv_lifnr = ls_value-value.
    ENDCASE.
  ENDLOOP.

  " Convert to internal format (ALPHA input)
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING input = lv_belnr
    IMPORTING output = lv_belnr.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING input = lv_lifnr
    IMPORTING output = lv_lifnr.

  IF lv_belnr IS INITIAL OR lv_lifnr IS INITIAL.
    lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
    lo_msg_container->add_message(
      EXPORTING
        iv_msg_type   = 'E'
        iv_msg_id     = 'SY'
        iv_msg_number = '000'
        iv_msg_text   = 'Document number (BELNR) and vendor (LIFNR) are mandatory parameters'
    ).
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid            = /iwbep/cx_mgw_busi_exception=>business_error
        message_container = lo_msg_container.
  ENDIF.

  SELECT SINGLE belnr ,gjahr, bukrs, lifnr, budat ,bldat, rmwwr ,waers
    INTO CORRESPONDING FIELDS OF @t_header
    FROM rbkp
    WHERE belnr = @lv_belnr
      AND lifnr = @lv_lifnr.

  IF sy-subrc <> 0.
    lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
    lo_msg_container->add_message(
      EXPORTING
        iv_msg_type   = 'E'
        iv_msg_id     = 'SY'
        iv_msg_number = '000'
        iv_msg_text   = 'Invoice not found for the provided document number and vendor'
    ).
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid            = /iwbep/cx_mgw_busi_exception=>business_error
        message_container = lo_msg_container.
  ENDIF.

  APPEND t_header TO lt_header.

  SELECT ebeln, ebelp, matnr, menge, meins, wrbtr, bstme
    INTO TABLE @DATA(lt_rseg)
    FROM rseg
    WHERE belnr = @lv_belnr.

  LOOP AT lt_rseg INTO DATA(ls_rseg).
    DATA(ls_item) = VALUE zmm_vinvoice_i_s(
      ebeln = ls_rseg-ebeln
      ebelp = ls_rseg-ebelp
      matnr = ls_rseg-matnr
      menge = ls_rseg-menge
      meins = ls_rseg-meins
      wrbtr = ls_rseg-wrbtr
      waers = t_header-waers ).

    SELECT SINGLE maktx INTO ls_item-maktx
      FROM makt
      WHERE matnr = ls_item-matnr
        AND spras = sy-langu.

    APPEND ls_item TO t_items.
  ENDLOOP.

  TRY.
      CALL FUNCTION 'FP_FUNCTION_MODULE_NAME'
        EXPORTING i_name = lc_form_name
        IMPORTING e_funcname = lv_funcname.
    CATCH cx_fp_exception INTO DATA(lx_fp_exception).
      lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
      lv_msg_text = lx_fp_exception->get_text( ).
      lo_msg_container->add_message(
        EXPORTING
          iv_msg_type   = 'E'
          iv_msg_id     = 'SY'
          iv_msg_number = '000'
          iv_msg_text   = lv_msg_text
      ).
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          textid            = /iwbep/cx_mgw_tech_exception=>internal_error
          message_container = lo_msg_container.
  ENDTRY.

  ls_output-nodialog = abap_true.
  ls_output-getpdf   = abap_true.

  TRY.
      CALL FUNCTION 'FP_JOB_OPEN'
        CHANGING ie_outputparams = ls_output.
      IF sy-subrc <> 0.
        lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
        lo_msg_container->add_message(
          EXPORTING
            iv_msg_type   = 'E'
            iv_msg_id     = 'SY'
            iv_msg_number = '000'
            iv_msg_text   = 'Failed to open Adobe Form job'
        ).
        RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
          EXPORTING
            textid            = /iwbep/cx_mgw_tech_exception=>internal_error
            message_container = lo_msg_container.
      ENDIF.

      ls_docparams-langu   = sy-langu.
      ls_docparams-country = 'IN'.

      CALL FUNCTION lv_funcname
        EXPORTING
          /1bcdwb/docparams = ls_docparams
          i_invoice_id      = lv_belnr
          i_vendor_id       = lv_lifnr
        IMPORTING
          /1bcdwb/formoutput = ls_formoutput
        TABLES
          t_header           = lt_header
          t_items            = t_items.

      CALL FUNCTION 'FP_JOB_CLOSE'.

    CATCH /iwbep/cx_mgw_tech_exception INTO DATA(lx_tech_exception).
      CALL FUNCTION 'FP_JOB_CLOSE'.
      lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
      lv_msg_text = lx_tech_exception->get_text( ).
      lo_msg_container->add_message(
        EXPORTING
          iv_msg_type   = 'E'
          iv_msg_id     = 'SY'
          iv_msg_number = '000'
          iv_msg_text   = lv_msg_text
      ).
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
        EXPORTING
          previous          = lx_tech_exception
          textid            = /iwbep/cx_mgw_tech_exception=>internal_error
          message_container = lo_msg_container.
  ENDTRY.

  IF ls_formoutput-pdf IS INITIAL.
    lo_msg_container = /iwbep/cl_mgw_msg_container=>get_mgw_msg_container( ).
    lo_msg_container->add_message(
      EXPORTING
        iv_msg_type   = 'E'
        iv_msg_id     = 'SY'
        iv_msg_number = '000'
        iv_msg_text   = 'No PDF generated by Adobe Form'
    ).
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_tech_exception
      EXPORTING
        textid            = /iwbep/cx_mgw_tech_exception=>internal_error
        message_container = lo_msg_container.
  ENDIF.

  ls_stream-value     = ls_formoutput-pdf.
  ls_stream-mime_type = 'application/pdf'.

  copy_data_to_ref(
    EXPORTING is_data = ls_stream
    CHANGING cr_data = er_stream ).

ENDMETHOD.
ENDCLASS.
