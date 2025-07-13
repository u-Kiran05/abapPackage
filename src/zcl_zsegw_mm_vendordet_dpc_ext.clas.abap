class ZCL_ZSEGW_MM_VENDORDET_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_MM_VENDORDET_DPC
  create public .

public section.
protected section.

  methods ZPOHEADERSET_GET_ENTITYSET
    redefinition .
  methods ZPOITEMSET_GET_ENTITYSET
    redefinition .
  methods ZRFQHEADERSET_GET_ENTITYSET
    redefinition .
  methods ZRFQITEMSET_GET_ENTITYSET
    redefinition .
  methods ZGRDETAILSSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_MM_VENDORDET_DPC_EXT IMPLEMENTATION.


METHOD zgrdetailsset_get_entityset.

  DATA: lt_gr    TYPE STANDARD TABLE OF zmm_vgr_s,
        lv_lifnr TYPE lifnr.

  " Extract single Lifnr value from filter
  LOOP AT it_filter_select_options INTO DATA(ls_filter) WHERE property = 'Lifnr'.
    READ TABLE ls_filter-select_options INTO DATA(ls_selopt) INDEX 1.
    IF sy-subrc = 0 AND ls_selopt-low IS NOT INITIAL AND ls_selopt-high IS INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = ls_selopt-low
        IMPORTING output = lv_lifnr.
    ELSE.
      RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
        EXPORTING
          textid  = /iwbep/cx_mgw_busi_exception=>business_error
          message = 'Only a single Lifnr value is allowed, range or high value not supported'.
    ENDIF.
    EXIT. " Exit after first match
  ENDLOOP.

  IF lv_lifnr IS INITIAL.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = 'Vendor filter (LIFNR) is mandatory'.
  ENDIF.

  " Get GR data
  SELECT m~mblnr, m~mjahr, m~ebeln, m~ebelp, m~matnr, m~menge, m~werks, m~meins,
         k~budat, k~bldat, m~lifnr, m~bwart,
         e~waers
    FROM mseg AS m
    INNER JOIN mkpf AS k
      ON m~mblnr = k~mblnr AND m~mjahr = k~mjahr
    LEFT OUTER JOIN ekko AS e
      ON m~ebeln = e~ebeln
    WHERE m~lifnr = @lv_lifnr
      AND m~bwart IN ('101', '102')
      AND m~ebeln IS NOT INITIAL
    INTO CORRESPONDING FIELDS OF TABLE @lt_gr.

  IF sy-subrc <> 0.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = 'No Goods Receipts found for the specified vendor'.
  ENDIF.

  " Return to OData
  et_entityset = lt_gr.

ENDMETHOD.


METHOD zpoheaderset_get_entityset.

  DATA: lt_header TYPE zmm_vpo_t,
        lv_lifnr  TYPE lifnr.

  " Extract filter value for Lifnr
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    IF ls_filter-property = 'Lifnr'.
      READ TABLE ls_filter-select_options INTO DATA(ls_selopt) INDEX 1.
      IF sy-subrc = 0.
        lv_lifnr = ls_selopt-low.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Convert LIFNR to internal format
  IF lv_lifnr IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_lifnr
      IMPORTING
        output = lv_lifnr.

    " Select from EKKO based on LIFNR
    SELECT ebeln, bukrs, lifnr, bedat, bstyp, bsart
      INTO CORRESPONDING FIELDS OF TABLE @lt_header
      FROM ekko
      WHERE lifnr = @lv_lifnr.
  ENDIF.

  et_entityset = lt_header.

ENDMETHOD.


  method ZPOITEMSET_GET_ENTITYSET.
  DATA: lt_items TYPE zmm_vpo_i_t,
        lv_ebeln TYPE ekpo-ebeln.

  " Get the EBELN from the navigation key
  READ TABLE it_key_tab INTO DATA(ls_key) WITH KEY name = 'Ebeln'.
  IF sy-subrc = 0.
    lv_ebeln = ls_key-value.

    " Convert to internal format with leading zeros
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_ebeln
      IMPORTING
        output = lv_ebeln.

    " Fetch items from EKPO for given EBELN
    SELECT ebeln, ebelp, matnr, menge, werks, netwr
      INTO CORRESPONDING FIELDS OF TABLE @lt_items
      FROM ekpo
      WHERE ebeln = @lv_ebeln.
  ENDIF.

  et_entityset = lt_items.
  endmethod.


  method ZRFQHEADERSET_GET_ENTITYSET.
 DATA: lt_header TYPE zmm_vrfq_t,
        lv_lifnr  TYPE ekko-lifnr.

  " Extract LIFNR filter
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    IF ls_filter-property = 'Lifnr'.
      READ TABLE ls_filter-select_options INTO DATA(ls_selopt) INDEX 1.
      IF sy-subrc = 0.
        lv_lifnr = ls_selopt-low.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING input  = lv_lifnr
          IMPORTING output = lv_lifnr.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Select from EKKO where BSART = 'AN' (RFQ)
  SELECT ebeln, bukrs, lifnr, bedat, frgke, bsart, ekorg, ekgrp, waers
    INTO CORRESPONDING FIELDS OF TABLE @lt_header
    FROM ekko
    WHERE bsart = 'AN'
      AND lifnr = @lv_lifnr.

  et_entityset = lt_header.
  endmethod.


  method ZRFQITEMSET_GET_ENTITYSET.
  DATA: lt_items TYPE zmm_vrfq_i_t,
        lv_ebeln TYPE ekpo-ebeln.

  " Get EBELN from navigation key
  READ TABLE it_key_tab INTO DATA(ls_key) WITH KEY name = 'Ebeln'.
  IF sy-subrc = 0.
    lv_ebeln = ls_key-value.

    " Convert to internal format
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_ebeln
      IMPORTING
        output = lv_ebeln.

    " Fetch from EKPO
    SELECT ebeln, ebelp, matnr, meins
      INTO CORRESPONDING FIELDS OF TABLE @lt_items
      FROM ekpo
      WHERE ebeln = @lv_ebeln.


  ENDIF.
et_entityset = lt_items.
  endmethod.
ENDCLASS.
