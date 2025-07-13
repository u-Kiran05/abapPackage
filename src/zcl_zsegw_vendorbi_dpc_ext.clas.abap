class ZCL_ZSEGW_VENDORBI_DPC_EXT definition
  public
  inheriting from ZCL_ZSEGW_VENDORBI_DPC
  create public .

public section.
protected section.

  methods ZBIDETAILSSET_GET_ENTITYSET
    redefinition .
private section.
ENDCLASS.



CLASS ZCL_ZSEGW_VENDORBI_DPC_EXT IMPLEMENTATION.


METHOD zbidetailsset_get_entityset.

  DATA: lt_result       TYPE zmm_vendorbi_t,
        ls_result       TYPE zmm_vendorbi_s.

  DATA: lt_lifnr_filter TYPE RANGE OF lifnr,
        ls_filter       TYPE /iwbep/s_mgw_select_option,
        ls_selopt       TYPE /iwbep/s_cod_select_option.

  TYPES: BEGIN OF ty_agepair,
           lifnr  TYPE lifnr,
           budat  TYPE budat,
           zfbdt  TYPE bseg-zfbdt,
         END OF ty_agepair.

  TYPES: BEGIN OF ty_aging,
           lifnr           TYPE lifnr,
           total_days      TYPE i,
           count_entries   TYPE i,
         END OF ty_aging.

  TYPES: BEGIN OF ty_month,
           month  TYPE char6,
           amount TYPE wrbtr,
         END OF ty_month.

  TYPES: BEGIN OF ty_invoice,
           lifnr TYPE lifnr,
           wrbtr TYPE wrbtr,
           blart TYPE blart,
         END OF ty_invoice.

  DATA: lt_datepairs     TYPE STANDARD TABLE OF ty_agepair,
        lt_aging         TYPE STANDARD TABLE OF ty_aging,
        ls_aging         TYPE ty_aging,
        lt_invoice       TYPE STANDARD TABLE OF ty_invoice,
        lv_days          TYPE i,
        lv_inv_total     TYPE wrbtr,
        lv_inv_count     TYPE i,
        lt_month_json    TYPE STANDARD TABLE OF ty_month,
        lv_json_string   TYPE string.

  " Extract $filter for Lifnr
  LOOP AT it_filter_select_options INTO ls_filter WHERE property = 'Lifnr'.
    LOOP AT ls_filter-select_options INTO ls_selopt.
      APPEND VALUE #( sign = ls_selopt-sign
                      option = ls_selopt-option
                      low = ls_selopt-low
                      high = ls_selopt-high ) TO lt_lifnr_filter.
    ENDLOOP.
  ENDLOOP.

  " ALPHA_INPUT
  LOOP AT lt_lifnr_filter INTO DATA(ls_fix).
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING input = ls_fix-low
      IMPORTING output = ls_fix-low.
    IF ls_fix-high IS NOT INITIAL.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING input = ls_fix-high
        IMPORTING output = ls_fix-high.
    ENDIF.
    MODIFY lt_lifnr_filter FROM ls_fix.
  ENDLOOP.

  " --- DB SELECTS ---
  SELECT lifnr, SUM( rmwwr ) AS total_spend
    INTO TABLE @DATA(lt_spend)
    FROM rbkp
    WHERE lifnr IN @lt_lifnr_filter
    GROUP BY lifnr.

  SELECT lifnr, COUNT(*) AS total_po_count
    INTO TABLE @DATA(lt_po)
    FROM ekko
    WHERE lifnr IN @lt_lifnr_filter
    GROUP BY lifnr.

  SELECT lifnr,
         SUM( CASE WHEN shkzg = 'H' THEN wrbtr ELSE 0 END ) AS credit_total,
         SUM( CASE WHEN shkzg = 'S' THEN wrbtr ELSE 0 END ) AS debit_total
    INTO TABLE @DATA(lt_cd)
    FROM bseg
    WHERE lifnr IN @lt_lifnr_filter
    GROUP BY lifnr.

  SELECT lifnr, COUNT(*) AS open_po_count
    INTO TABLE @DATA(lt_open_po)
    FROM ekko
    WHERE lifnr IN @lt_lifnr_filter
      AND frgke <> 'R'
    GROUP BY lifnr.

  SELECT b~lifnr, a~budat, b~zfbdt
    INTO TABLE @lt_datepairs
    FROM bkpf AS a
    INNER JOIN bseg AS b ON a~belnr = b~belnr AND a~gjahr = b~gjahr
    WHERE b~lifnr IN @lt_lifnr_filter AND b~zfbdt <> '00000000'.

  " --- Monthly Spend (last 6 months) ---
  SELECT lifnr, budat, SUM( rmwwr ) AS amount
    FROM rbkp
    WHERE lifnr IN @lt_lifnr_filter
      AND budat >= ADD_MONTHS( @sy-datum, -6 )
    GROUP BY lifnr, budat
    INTO TABLE @DATA(lt_temp_spend).

  " --- Invoices ---
  SELECT b~lifnr, b~wrbtr, a~blart
    INTO CORRESPONDING FIELDS OF TABLE @lt_invoice
    FROM bseg AS b
    INNER JOIN bkpf AS a ON a~belnr = b~belnr AND a~gjahr = b~gjahr
    WHERE b~lifnr IN @lt_lifnr_filter AND a~blart = 'RE'.
" --- Aging Calculation ---
" --- Aging ---
DATA: lv_idx       TYPE sy-tabix.
CLEAR: lt_aging.

LOOP AT lt_datepairs INTO DATA(ls_pair).
  IF ls_pair-zfbdt IS INITIAL OR ls_pair-budat IS INITIAL OR
     ls_pair-zfbdt = '00000000' OR ls_pair-budat = '00000000'.
    CONTINUE.
  ENDIF.

  READ TABLE lt_aging INTO ls_aging WITH KEY lifnr = ls_pair-lifnr.
  lv_idx = sy-tabix.

  IF sy-subrc <> 0.
    CLEAR ls_aging.
    ls_aging-lifnr = ls_pair-lifnr.
    APPEND ls_aging TO lt_aging.
    READ TABLE lt_aging INTO ls_aging WITH KEY lifnr = ls_pair-lifnr.
    lv_idx = sy-tabix.
  ENDIF.

  CLEAR lv_days.
  CALL METHOD cl_reca_date=>get_days_between_two_dates
    EXPORTING
      id_datefrom = ls_pair-zfbdt
      id_dateto   = ls_pair-budat
    RECEIVING
      rd_days     = lv_days.

  "lv_days = abs( lv_days ).
  ls_aging-total_days    += lv_days.
  ls_aging-count_entries += 1.
  MODIFY lt_aging FROM ls_aging INDEX lv_idx.
ENDLOOP.




  " --- Final Output Construction ---
  LOOP AT lt_lifnr_filter INTO DATA(ls_range).
    CLEAR: ls_result, lv_inv_total, lv_inv_count, lv_json_string, lt_month_json.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING input = ls_range-low
      IMPORTING output = ls_result-lifnr.

    SELECT SINGLE name1 INTO ls_result-name1 FROM lfa1 WHERE lifnr = ls_range-low.
    SELECT SINGLE waers INTO ls_result-currency FROM ekko WHERE lifnr = ls_range-low.

    READ TABLE lt_spend INTO DATA(sp) WITH KEY lifnr = ls_range-low.
    IF sy-subrc = 0. ls_result-total_spend = sp-total_spend. ENDIF.

    READ TABLE lt_po INTO DATA(po) WITH KEY lifnr = ls_range-low.
    IF sy-subrc = 0. ls_result-total_po_count = po-total_po_count. ENDIF.

    READ TABLE lt_open_po INTO DATA(openpo) WITH KEY lifnr = ls_range-low.
    IF sy-subrc = 0. ls_result-open_po_count = openpo-open_po_count. ENDIF.

    READ TABLE lt_cd INTO DATA(cd) WITH KEY lifnr = ls_range-low.
    IF sy-subrc = 0.
      ls_result-credit_total = cd-credit_total.
      ls_result-debit_total  = cd-debit_total.
    ENDIF.

DATA: lv_avg_days TYPE f.

READ TABLE lt_aging INTO ls_aging WITH KEY lifnr = ls_range-low.
IF sy-subrc = 0 AND ls_aging-count_entries > 0.

  " Float division
  lv_avg_days = ls_aging-total_days / ls_aging-count_entries.

  " Rounded integer result
  ls_result-avg_aging_days = ROUND( val = lv_avg_days dec = 0 ).

ELSE.
  ls_result-avg_aging_days = 0.
ENDIF.





    IF ls_result-total_po_count > 0 AND ls_result-total_spend IS NOT INITIAL.
      ls_result-avg_spend_per_po = ls_result-total_spend / ls_result-total_po_count.
    ENDIF.

    LOOP AT lt_invoice INTO DATA(inv) WHERE lifnr = ls_range-low.
      lv_inv_total += inv-wrbtr.
      lv_inv_count += 1.
    ENDLOOP.

    ls_result-invoice_count = lv_inv_count.
    IF lv_inv_count > 0.
      ls_result-avg_invoice_value = lv_inv_total / lv_inv_count.
    ENDIF.

    " --- Monthly Spend JSON using /UI2/CL_JSON ---
    LOOP AT lt_temp_spend INTO DATA(temp) WHERE lifnr = ls_range-low.
      DATA(ms_entry) = VALUE ty_month( ).
      CONCATENATE temp-budat+0(4) temp-budat+4(2) INTO ms_entry-month.
      ms_entry-amount = temp-amount.
      APPEND ms_entry TO lt_month_json.
    ENDLOOP.

    IF lt_month_json IS NOT INITIAL.
      TRY.
          CALL METHOD /ui2/cl_json=>serialize
            EXPORTING
              data        = lt_month_json
              pretty_name = /ui2/cl_json=>pretty_mode-camel_case
            RECEIVING
              r_json      = lv_json_string.
        CATCH cx_root INTO DATA(lx_json).
          lv_json_string = '[]'.
      ENDTRY.

      " Ensure JSON fits CHAR2048
      IF strlen( lv_json_string ) > 2048.
        ls_result-month_spend_json = lv_json_string(2048).
      ELSE.
        ls_result-month_spend_json = lv_json_string.
      ENDIF.
    ENDIF.

    APPEND ls_result TO lt_result.
  ENDLOOP.

  et_entityset = lt_result.

ENDMETHOD.
ENDCLASS.
