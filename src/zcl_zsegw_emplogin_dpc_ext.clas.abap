class ZCL_ZSEGW_EMPLOGIN_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_EMPLOGIN_DPC
  create public .

public section.
protected section.

  methods ZEMPLOGINSET_CREATE_ENTITY
    redefinition .
  methods ZEMPLOGINSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_EMPLOGIN_DPC_EXT IMPLEMENTATION.


METHOD zemploginset_create_entity.

  " Declare local variables
  DATA: ls_input    TYPE zcl_zsegw_emplogin_mpc=>ts_zemplogin,
        ls_response TYPE zcl_zsegw_emplogin_mpc=>ts_zemplogin,
        lv_password TYPE zhcm_epass_de,
        lv_result   TYPE char1 VALUE 'N',
        lv_empid    TYPE pernr_d.

  " Read payload
  io_data_provider->read_entry_data(
    IMPORTING es_data = ls_input
  ).

  " ALPHA conversion for EMP_ID (if defined with conversion exit)
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = ls_input-emp_id
    IMPORTING
      output = lv_empid.

  " Check employee existence and password
  SELECT SINGLE employee_pass INTO @lv_password
    FROM zhcm_elogin
    WHERE employee_id = @lv_empid.

  IF sy-subrc = 0 AND lv_password = ls_input-password.
    lv_result = 'Y'.
  ENDIF.

  " Set response
  ls_response-emp_id = ls_input-emp_id.   " Keep original unconverted ID for response
  ls_response-status = lv_result.

  " Return result
  er_entity = ls_response.

ENDMETHOD.


  method ZEMPLOGINSET_GET_ENTITYSET.
**TRY.
*CALL METHOD SUPER->ZEMPLOGINSET_GET_ENTITYSET
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
    CLEAR et_entityset.
  endmethod.
ENDCLASS.
