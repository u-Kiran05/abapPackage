class ZCL_ZVENDOR_LOGINK_DPC_EXT definition
  public
  inheriting from ZCL_ZVENDOR_LOGINK_DPC
  create public .

public section.
protected section.

  methods ZMM_VLOGIN_TSET_CREATE_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZVENDOR_LOGINK_DPC_EXT IMPLEMENTATION.


METHOD zmm_vlogin_tset_create_entity.

  DATA: ls_input    TYPE zmm_vlogin_t,
        lv_password TYPE zmm_vpass_de,
        lv_vendor   TYPE lifnr.

  " Read input data
  io_data_provider->read_entry_data( IMPORTING es_data = ls_input ).

  " Check if Vendor exists in standard Vendor Master (LFA1)
  SELECT SINGLE lifnr FROM lfa1 INTO @lv_vendor
    WHERE lifnr = @ls_input-vendor_id.

  IF sy-subrc <> 0.
    " Vendor not found
    er_entity = 'N'.
    RETURN.
  ENDIF.

  " Validate password from Z-table
  SELECT SINGLE password FROM zmm_vlogin_t INTO @lv_password
    WHERE vendor_id = @ls_input-vendor_id.

  IF sy-subrc <> 0 OR lv_password <> ls_input-password.
    " Invalid password
    er_entity = 'N'.
    RETURN.
  ENDIF.

  " Successful authentication
  er_entity = 'Y'.

ENDMETHOD.
ENDCLASS.
