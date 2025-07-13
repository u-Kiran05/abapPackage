class ZCL_ZSEGW_SF_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_SF_DPC
  create public .

public section.
protected section.

  methods ZPLANNEDDETAILSS_GET_ENTITYSET
    redefinition .
  methods ZPRODUCTIONDETAI_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_SF_DPC_EXT IMPLEMENTATION.


METHOD zplanneddetailss_get_entityset.

  DATA: lt_data         TYPE TABLE OF plaf,
        ls_structure    TYPE zshop_plan_s,
        lv_plwrk        TYPE plwrk,
        lv_startyear    TYPE numc4,
        lv_startmonth   TYPE numc2,
        lv_endyear      TYPE numc4,
        lv_endmonth     TYPE numc2.

  " Extract filter values from $filter
  LOOP AT it_filter_select_options INTO DATA(ls_filter).
    READ TABLE ls_filter-select_options INTO DATA(ls_option) INDEX 1.
    IF sy-subrc = 0 AND ls_option-option = 'EQ'.
      CASE ls_filter-property.
        WHEN 'Plantcode'.   lv_plwrk      = ls_option-low.
        WHEN 'Startyear'.   lv_startyear  = ls_option-low.
        WHEN 'Startmonth'.  lv_startmonth = ls_option-low.
        WHEN 'Endyear'.     lv_endyear    = ls_option-low.
        WHEN 'Endmonth'.    lv_endmonth   = ls_option-low.
      ENDCASE.
    ENDIF.
  ENDLOOP.

  " Validate plant code
  IF lv_plwrk IS INITIAL.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = 'PLANTCODE is required'.
  ENDIF.

  " Select planned order data
  SELECT a~plnum,
         a~matnr,
         b~maktx,
         a~gsmng,
         a~meins,
         a~plwrk,
         c~name1,
         a~plgrp,
         f~txt,
         a~dispo,
         d~dsnam,
         a~ststa,
         e~sttxt,
         a~pertr,
         a~psttr,
         a~pedtr
    INTO TABLE @DATA(lt_orders)
    FROM plaf AS a
    LEFT JOIN makt  AS b ON a~matnr = b~matnr AND b~spras = @sy-langu
    LEFT JOIN t001w AS c ON a~plwrk = c~werks
    LEFT JOIN t024d AS d ON a~dispo = d~dispo
    LEFT JOIN t415t AS e ON a~ststa = e~stlst AND e~spras = @sy-langu
    LEFT JOIN t024f AS f ON a~plgrp = f~fevor
    WHERE a~plwrk = @lv_plwrk.

  LOOP AT lt_orders INTO DATA(ls_data).
    CLEAR ls_structure.

    DATA(start_year)  = ls_data-psttr+0(4).
    DATA(start_month) = ls_data-psttr+4(2).
    DATA(end_year)    = ls_data-pedtr+0(4).
    DATA(end_month)   = ls_data-pedtr+4(2).

    " Apply optional filters
    IF lv_startmonth IS NOT INITIAL AND
       lv_startmonth <> start_month AND
       lv_startmonth <> end_month.
      CONTINUE.
    ENDIF.

    IF lv_startyear IS NOT INITIAL AND
       lv_startyear <> start_year AND
       lv_startyear <> end_year.
      CONTINUE.
    ENDIF.

    " Populate the structure using WF_ fields
    ls_structure-wf_orderno         = ls_data-plnum.
    ls_structure-wf_matno           = ls_data-matnr.
    ls_structure-wf_matdesc         = ls_data-maktx.
    ls_structure-wf_orderquant      = ls_data-gsmng.
    ls_structure-wf_unit            = ls_data-meins.
    ls_structure-wf_plantcode       = ls_data-plwrk.
    ls_structure-wf_plantname       = ls_data-name1.
    ls_structure-wf_groupcode       = ls_data-plgrp.
    ls_structure-wf_groupname       = ls_data-txt.
    ls_structure-wf_controllercode  = ls_data-dispo.
    ls_structure-wf_controllername  = ls_data-dsnam.
    ls_structure-wf_statuscode      = ls_data-ststa.
    ls_structure-wf_statustxt       = ls_data-sttxt.
    ls_structure-wf_openingdate     = ls_data-pertr.
    ls_structure-wf_startdate       = ls_data-psttr.
    ls_structure-wf_enddate         = ls_data-pedtr.
    ls_structure-wf_startyear       = start_year.
    ls_structure-wf_startmonth      = start_month.
    ls_structure-wf_endyear         = end_year.
    ls_structure-wf_endmonth        = end_month.

    APPEND ls_structure TO et_entityset.
  ENDLOOP.

ENDMETHOD.


METHOD ZPRODUCTIONDETAI_GET_ENTITYSET.

  DATA: ls_entity         TYPE ZSF_PROD_S,
        lt_entity         TYPE ZSF_PROD_T,
        lv_plantcode      TYPE werks_d,
        ls_filter         TYPE /iwbep/s_mgw_select_option,
        ls_select         TYPE /iwbep/s_cod_select_option,
        lv_matnr          TYPE matnr,
        lv_spras          TYPE sy-langu,
        lv_startdate      TYPE datum,
        lv_enddate        TYPE datum,
        lv_startmonth     TYPE char2,
        lv_startyear      TYPE char4,
        lv_endmonth       TYPE char2,
        lv_endyear        TYPE char4,
        ls_aufk           TYPE aufk,
        ls_afko           TYPE afko,
        ls_makt           TYPE makt,
        ls_t001w          TYPE t001w,
        lt_aufk           TYPE STANDARD TABLE OF aufk.

  lv_spras = sy-langu.

  " Extract filters from OData
  LOOP AT it_filter_select_options INTO ls_filter.
    CASE ls_filter-property.
      WHEN 'PlantCode'.
        READ TABLE ls_filter-select_options INTO ls_select INDEX 1.
        IF sy-subrc = 0 AND ls_select-option = 'EQ' AND ls_select-sign = 'I'.
          lv_plantcode = ls_select-low.
        ENDIF.
      WHEN 'Startmonth'.
        READ TABLE ls_filter-select_options INTO ls_select INDEX 1.
        IF sy-subrc = 0.
          lv_startmonth = ls_select-low.
        ENDIF.
      WHEN 'Startyear'.
        READ TABLE ls_filter-select_options INTO ls_select INDEX 1.
        IF sy-subrc = 0.
          lv_startyear = ls_select-low.
        ENDIF.
      WHEN 'Endmonth'.
        READ TABLE ls_filter-select_options INTO ls_select INDEX 1.
        IF sy-subrc = 0.
          lv_endmonth = ls_select-low.
        ENDIF.
      WHEN 'Endyear'.
        READ TABLE ls_filter-select_options INTO ls_select INDEX 1.
        IF sy-subrc = 0.
          lv_endyear = ls_select-low.
        ENDIF.
    ENDCASE.
  ENDLOOP.

  " Validate mandatory plant input
  IF lv_plantcode IS INITIAL.
    RAISE EXCEPTION TYPE /iwbep/cx_mgw_busi_exception
      EXPORTING
        textid  = /iwbep/cx_mgw_busi_exception=>business_error
        message = 'PLANT_CODE filter is required'.
  ENDIF.

  " Read Production Orders from AUFK
  SELECT * INTO TABLE @lt_aufk FROM aufk WHERE werks = @lv_plantcode.

  LOOP AT lt_aufk INTO ls_aufk.
    CLEAR: ls_entity, ls_afko, ls_makt, ls_t001w,
           lv_matnr, lv_startdate, lv_enddate.

    " Get AFKO entry
    SELECT SINGLE * INTO @ls_afko FROM afko WHERE aufnr = @ls_aufk-aufnr.
    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.

    lv_matnr     = ls_afko-plnbez.
    lv_startdate = ls_afko-gstrp.
    lv_enddate   = ls_afko-gltrp.

    " Get material description
    SELECT SINGLE * INTO @ls_makt
      FROM makt WHERE matnr = @lv_matnr AND spras = @lv_spras.

    " Get plant name
    SELECT SINGLE * INTO @ls_t001w FROM t001w WHERE werks = @ls_aufk-werks.

    " Fill entity
    ls_entity-ORDER_TYPE_CODE    = ls_aufk-auart.
    ls_entity-ORDERNO            = ls_aufk-aufnr.
    ls_entity-ORDER_TYPE_TEXT    = ls_aufk-ktext.
    ls_entity-COMPANY_CODE       = ls_aufk-bukrs.
    ls_entity-MATERIAL_NO        = lv_matnr.
    ls_entity-MATERIAL_DESC      = ls_makt-maktx.
    ls_entity-PLANT_CODE         = ls_aufk-werks.
    ls_entity-PLANT_NAME         = ls_t001w-name1.
    ls_entity-ORDERQUANTITY      = ls_afko-gamng.
    ls_entity-UNITOFMEASURE      = ls_afko-gmein.
    ls_entity-STARTDATE          = lv_startdate.
    ls_entity-ENDDATE            = lv_enddate.
    ls_entity-ORDERCATEGORY      = ls_aufk-autyp.

    IF lv_startdate > '00000000'.
      ls_entity-STARTMONTH = lv_startdate+4(2).
      ls_entity-STARTYEAR  = lv_startdate+0(4).
    ENDIF.
    IF lv_enddate > '00000000'.
      ls_entity-ENDMONTH   = lv_enddate+4(2).
      ls_entity-ENDYEAR    = lv_enddate+0(4).
    ENDIF.

    " Apply optional month/year filter
    IF ( lv_startmonth IS NOT INITIAL AND ls_entity-startmonth <> lv_startmonth )
     OR ( lv_startyear IS NOT INITIAL AND ls_entity-startyear <> lv_startyear )
     OR ( lv_endmonth IS NOT INITIAL AND ls_entity-endmonth <> lv_endmonth )
     OR ( lv_endyear IS NOT INITIAL AND ls_entity-endyear <> lv_endyear ).
      CONTINUE.
    ENDIF.

    APPEND ls_entity TO lt_entity.
  ENDLOOP.

  " Return the result set
  et_entityset = lt_entity.

  IF io_tech_request_context->has_inlinecount( ) = abap_true.
    es_response_context-inlinecount = lines( lt_entity ).
  ENDIF.

ENDMETHOD.
ENDCLASS.
