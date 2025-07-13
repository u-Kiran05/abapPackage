class ZCL_ZSEGW_VENDORDETAIL_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_VENDORDETAIL_DPC
  create public .

public section.
protected section.

  methods ZCDDETAILSSET_GET_ENTITYSET
    redefinition .
  methods ZINVHEADERSET_GET_ENTITYSET
    redefinition .
  methods ZINVITEMSSET_GET_ENTITYSET
    redefinition .
  methods ZAGDETAILSSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_VENDORDETAIL_DPC_EXT IMPLEMENTATION.


METHOD zagdetailsset_get_entityset.

  DATA: lt_aging TYPE zmm_vaging_t,
        ls_aging TYPE LINE OF zmm_vaging_t,
        lv_lifnr TYPE lifnr.

  " --- 1. Extract LIFNR from OData filter ---
  LOOP AT it_filter_select_options INTO DATA(ls_filter) WHERE property = 'Lifnr'.
    READ TABLE ls_filter-select_options INTO DATA(ls_option) INDEX 1.
    IF sy-subrc = 0.
      lv_lifnr = ls_option-low.
    ENDIF.
  ENDLOOP.

  " --- 2. ALPHA conversion for vendor number ---
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING input  = lv_lifnr
    IMPORTING output = lv_lifnr.

  " --- 3. Select financial document data ---
  SELECT a~belnr,
         a~gjahr,
         b~budat,
         a~zfbdt,
         a~wrbtr,
         a~wmwst,
         b~waers,
         a~lifnr,
         a~mwskz
    INTO CORRESPONDING FIELDS OF TABLE @lt_aging
    FROM bseg AS a
    INNER JOIN bkpf AS b ON a~belnr = b~belnr AND a~gjahr = b~gjahr
    WHERE a~lifnr = @lv_lifnr
      AND a~zfbdt <> '00000000'.

  " --- 4. Calculate net amount and days aging ---
  LOOP AT lt_aging INTO ls_aging.

    IF ls_aging-zfbdt IS NOT INITIAL AND ls_aging-zfbdt <> '00000000'.

      " Net amount = gross - tax
      ls_aging-net_amount = ls_aging-wrbtr - ls_aging-wmwst.

      " Aging = Today's date - Due date (ZFBDT)
      ls_aging-days_aging = sy-datum - ls_aging-zfbdt.

      MODIFY lt_aging FROM ls_aging.

    ENDIF.

  ENDLOOP.

  " --- 5. Return result set ---
  et_entityset = lt_aging.

ENDMETHOD.


METHOD zcddetailsset_get_entityset.

  DATA: lv_lifnr  TYPE lifnr,
        lt_data   TYPE zmm_vcandd_t,
        ls_data   TYPE zmm_vcandd_s.

  DATA: ls_filter TYPE /iwbep/s_mgw_select_option,
        ls_selopt TYPE /iwbep/s_cod_select_option.

  " Extract single Lifnr from $filter
  LOOP AT it_filter_select_options INTO ls_filter WHERE property = 'Lifnr'.
    READ TABLE ls_filter-select_options INTO ls_selopt INDEX 1.
    IF sy-subrc = 0 AND ls_selopt-low IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input  = ls_selopt-low
        IMPORTING output = lv_lifnr.
    ENDIF.
  ENDLOOP.

  " Main DB read (for single Lifnr)
  SELECT a~belnr, a~gjahr, a~bukrs, b~lifnr,
         a~budat, a~bldat, a~blart,
         b~wrbtr, a~waers, b~shkzg
    INTO CORRESPONDING FIELDS OF TABLE @lt_data
    FROM bkpf AS a
    INNER JOIN bseg AS b
      ON a~bukrs = b~bukrs
     AND a~belnr = b~belnr
     AND a~gjahr = b~gjahr
    WHERE b~lifnr = @lv_lifnr
      AND b~shkzg IN ('H', 'S').

  " Fill OData response
  LOOP AT lt_data INTO ls_data.
    APPEND ls_data TO et_entityset.
  ENDLOOP.

ENDMETHOD.


  method ZINVHEADERSET_GET_ENTITYSET.
 DATA: lt_header TYPE STANDARD TABLE OF zmm_vinvoice_s,
        lv_lifnr  TYPE lifnr.

  " Extract LIFNR from filters
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    IF ls_filter-property = 'Lifnr'.
      READ TABLE ls_filter-select_options INTO DATA(ls_selopt) INDEX 1.
      IF sy-subrc = 0.
        lv_lifnr = ls_selopt-low.
      ENDIF.
    ENDIF.
  ENDLOOP.

  " Convert Vendor to internal format
  IF lv_lifnr IS NOT INITIAL.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING input  = lv_lifnr
      IMPORTING output = lv_lifnr.

    " Select header data from RBKP
    SELECT belnr ,gjahr, bukrs ,lifnr, budat, bldat ,rmwwr ,waers
      INTO CORRESPONDING FIELDS OF TABLE @lt_header
      FROM rbkp
      WHERE lifnr = @lv_lifnr.
  ENDIF.

  et_entityset = lt_header.

  endmethod.


METHOD zinvitemsset_get_entityset.

  DATA: lt_items TYPE STANDARD TABLE OF zmm_vinvoice_i_s,
        lv_belnr TYPE belnr_d.

  READ TABLE it_key_tab INTO DATA(ls_key) WITH KEY name = 'Belnr'.
  IF sy-subrc = 0.
    lv_belnr = ls_key-value.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING input  = lv_belnr
      IMPORTING output = lv_belnr.

    " Correct SELECT without WAERS
    SELECT ebeln, ebelp, matnr, menge, meins, wrbtr, bstme
      INTO CORRESPONDING FIELDS OF TABLE @lt_items
      FROM rseg
      WHERE belnr = @lv_belnr.

    " Populate MAKTX using MAKT
    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<fs_item>).
      IF <fs_item>-matnr IS NOT INITIAL.
        SELECT SINGLE maktx
          INTO @<fs_item>-maktx
          FROM makt
          WHERE matnr = @<fs_item>-matnr
            AND spras = @sy-langu.
      ENDIF.
    ENDLOOP.
  ENDIF.

  et_entityset = lt_items.

ENDMETHOD.
ENDCLASS.
