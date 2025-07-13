class ZCL_ZVENDOR_LOGINK_01_DPC_EXT definition
  public
  inheriting from ZCL_ZVENDOR_LOGINK_01_DPC
  create public .

public section.
protected section.

  methods ZMM_VLOGIN_TSET_CREATE_ENTITY
    redefinition .
  methods ZMM_VLOGIN_TSET_GET_ENTITYSET
    redefinition .
  methods ZMM_VLOGIN_TSET_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZVENDOR_LOGINK_01_DPC_EXT IMPLEMENTATION.


METHOD zmm_vlogin_tset_create_entity.

DATA: ls_response TYPE zmm_vlogin_t,   " Response structure
        lv_password TYPE zmm_vpass_de,
        lv_vendor   TYPE lifnr,
        lv_result   TYPE c LENGTH 1 VALUE 'N'. " Default to 'N'

  " Read input data into work area
  DATA(ls_input) = VALUE zmm_vlogin_t( ).
  io_data_provider->read_entry_data( IMPORTING es_data = ls_input ).

  " Check if vendor exists
  SELECT SINGLE lifnr INTO lv_vendor
    FROM lfa1
    WHERE lifnr = ls_input-vendor_id.

  IF sy-subrc = 0.
    " Check password in Z-table
    SELECT SINGLE password INTO lv_password
      FROM zmm_vlogin_t
      WHERE vendor_id = ls_input-vendor_id.

    IF sy-subrc = 0 AND lv_password = ls_input-password.
      lv_result = 'Y'. " Valid vendor and password
    ENDIF.
  ENDIF.

  " Set the response with only the Status
  CLEAR ls_response.
  ls_response-status = lv_result.
  er_entity = ls_response.



ENDMETHOD.


  method ZMM_VLOGIN_TSET_GET_ENTITY.
  DATA: lv_vendor_id TYPE lifnr,
        ls_vendor    TYPE zmm_vlogin_t.

  " Get the key from the input parameter
  READ TABLE it_key_tab INTO DATA(ls_key) WITH KEY name = 'VendorId'.
  IF sy-subrc = 0.
    lv_vendor_id = ls_key-value.
  ELSE.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>entity_not_found.
  ENDIF.

  " Fetch vendor details from Z-table
  SELECT SINGLE vendor_id password status
    INTO CORRESPONDING FIELDS OF ls_vendor
    FROM zmm_vlogin_t
    WHERE vendor_id = lv_vendor_id.

  IF sy-subrc = 0.
    er_entity = ls_vendor.
  ELSE.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>entity_not_found.
  ENDIF.
  endmethod.


  method ZMM_VLOGIN_TSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->ZMM_VLOGIN_TSET_GET_ENTITYSET
*  EXPORTING
*    IV_ENTITY_NAME           =
*    IV_ENTITY_SET_NAME       =
*    IV_SOURCE_NAME           =
*    IT_FILTER_SELECT_OPTIONS =
*    IS_PAGING                =
*    IT_KEY_TAB               =
*    IT_NAVIGATION_PATH       =
*    IT_ORDER                 =
*    IV_FILTER_STRING         =
*    IV_SEARCH_STRING         =
**    io_tech_request_context  =
**  IMPORTING
**    et_entityset             =
**    es_response_context      =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.
 " Initialize empty entity set
  CLEAR et_entityset.
  endmethod.
ENDCLASS.
