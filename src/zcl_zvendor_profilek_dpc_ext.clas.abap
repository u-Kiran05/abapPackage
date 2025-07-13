class ZCL_ZVENDOR_PROFILEK_DPC_EXT definition
  public
  inheriting from ZCL_ZVENDOR_PROFILEK_DPC
  create public .

public section.
protected section.

  methods ZMM_VPROFILE_SSE_GET_ENTITY
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZVENDOR_PROFILEK_DPC_EXT IMPLEMENTATION.


METHOD zmm_vprofile_sse_get_entity.

  DATA: lv_lifnr TYPE lifnr,
        ls_vendor TYPE zmm_vprofile_s.

  READ TABLE it_key_tab INTO DATA(ls_key) WITH KEY name = 'Lifnr'.
  IF sy-subrc = 0.
    lv_lifnr = ls_key-value.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_lifnr
      IMPORTING
        output = lv_lifnr.
  ELSE.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>entity_not_found.
  ENDIF.

  SELECT SINGLE lifnr land1 name1 ort01 stras pstlz regio adrnr
    INTO CORRESPONDING FIELDS OF ls_vendor
    FROM lfa1
    WHERE lifnr = lv_lifnr.

  IF sy-subrc = 0.
    er_entity = ls_vendor.
  ELSE.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING textid = /iwbep/cx_mgw_busi_exception=>entity_not_found.
  ENDIF.

ENDMETHOD.
ENDCLASS.
