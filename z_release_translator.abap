*The MIT License (MIT)
*
*Copyright (c) 2016 Rainer Winkler, CubeServ
*
*Permission is hereby granted, free of charge, to any person obtaining a copy
*of this software and associated documentation files (the "Software"), to deal
*in the Software without restriction, including without limitation the rights
*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*copies of the Software, and to permit persons to whom the Software is
*furnished to do so, subject to the following conditions:
*
*The above copyright notice and this permission notice shall be included in all
*copies or substantial portions of the Software.
*
*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*SOFTWARE.

"! Last activation:
"! 20.03.2016 01:16 issue17 Rainer Winkler
"!
"! Keep logic compatible to ABAP 7.31 to allow also conversion into the other direction
REPORT z_release_translator.

"! Redefines abap_bool to simplify coding (Not always reading abap_...)
TYPES bool TYPE abap_bool.
CONSTANTS:
  "! Redefines abap_true to simplify coding (Not always reading abap_...)
  true  TYPE bool VALUE abap_true,
  "! Redefines abap_false to simplify coding (Not always reading abap_...)
  false TYPE bool VALUE abap_false.

TYPES: stringtable TYPE STANDARD TABLE OF string WITH DEFAULT KEY.



CLASS cl_read DEFINITION.
  PUBLIC SECTION.
    METHODS do
      RETURNING VALUE(source) TYPE stringtable.
ENDCLASS.

CLASS cl_read IMPLEMENTATION.

  METHOD do.
    READ REPORT 'YRW1_MOOSE_EXTRACTOR' INTO source.
  ENDMETHOD.

ENDCLASS.

CLASS cl_download DEFINITION.
  PUBLIC SECTION.
    METHODS do
      IMPORTING source TYPE stringtable.
ENDCLASS.

CLASS cl_download IMPLEMENTATION.

  METHOD do.
    " Download the file

    DATA: filename    TYPE string,
          pathname    TYPE string,
          fullpath    TYPE string,
          user_action TYPE i.



    cl_gui_frontend_services=>file_save_dialog( EXPORTING default_extension = 'abap'
                                                CHANGING  filename    = filename       " File Name to Save
                                                          path        = pathname       " Path to File
                                                          fullpath    = fullpath       " Path + File Name
                                                          user_action = user_action ). " User Action (C Class Const ACTION_OK, ACTION_OVERWRITE etc)

    IF user_action = cl_gui_frontend_services=>action_cancel.
      WRITE: / 'Canceled by user'.
    ELSE.

      CALL FUNCTION 'GUI_DOWNLOAD'
        EXPORTING
          filename = fullpath
        TABLES
          data_tab = source.

    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS cl_conversion DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF codeline_type,
             code      TYPE string,
             condensed TYPE string,
           END OF codeline_type.
    TYPES: codelines_type TYPE STANDARD TABLE OF codeline_type WITH KEY code.
    TYPES: BEGIN OF replace_type,
             replace_id TYPE i,
             only_once type true,
             abap_740   TYPE codelines_type,
             abap_731   TYPE codelines_type,
             replaced   TYPE i,
           END OF replace_type.
    TYPES: replaces_type TYPE STANDARD TABLE OF replace_type WITH KEY replace_id.
    DATA: g_replaces TYPE replaces_type.
    METHODS constructor.
    METHODS get_conversion
      RETURNING VALUE(replaces) TYPE replaces_type.
ENDCLASS.

CLASS cl_conversion IMPLEMENTATION.

  METHOD constructor.

    DATA: codeline           TYPE codeline_type,
          codelines_abap_740 TYPE codelines_type,
          codelines_abap_731 TYPE codelines_type,
          replace            TYPE replace_type,
          replace_id         TYPE i.

    replace_id = 1.

    DEFINE start_building_table.
      CLEAR codelines_abap_740.
      CLEAR codelines_abap_731.
    END-OF-DEFINITION.

    DEFINE add_abap_740.
      codeline-code = &1.
      codeline-condensed = &1.
      CONDENSE codeline-condensed.
      TRANSLATE codeline-condensed to UPPER CASE.
      APPEND codeline TO codelines_abap_740.
    END-OF-DEFINITION.

    DEFINE add_abap_731.
      codeline-code = &1.
      codeline-condensed = &1.
      CONDENSE codeline-condensed.
      TRANSLATE codeline-condensed to UPPER CASE.
      APPEND codeline TO codelines_abap_731.
    END-OF-DEFINITION.

    define only_once.

    replace-only_once = true.

    end-OF-DEFINITION.

    DEFINE add_replace.

      replace-replace_id = replace_id.
      replace-abap_740 = codelines_abap_740.
      replace-abap_731 = codelines_abap_731.

      g_replaces = value #( base g_replaces ( replace ) ).

      CLEAR codelines_abap_740.
      CLEAR codelines_abap_731.

      CLEAR replace.

      ADD 1 TO replace_id.

    END-OF-DEFINITION.

    DATA c740 TYPE string.
    DATA c731 TYPE string.

    start_building_table.
    add_abap_740 '      EXPORTING VALUE(exists_already_with_id) TYPE i'.
    add_abap_740 '      RETURNING VALUE(processed_id)           TYPE i.'.

    add_abap_731 '      EXPORTING value(exists_already_with_id) TYPE i'.
    add_abap_731 '                value(processed_id)           TYPE i.'.
    add_replace.

    " CLASS cl_model

    add_abap_740 '  METHOD add_entity.'.
    add_abap_740 ''.
    add_abap_740 '    IF can_be_referenced_by_name EQ true.'.
    add_abap_740 ''.
    add_abap_740 '      READ TABLE g_named_entities ASSIGNING FIELD-SYMBOL(<ls_name>) WITH TABLE KEY elementname = elementname name_group = name_group xname = name.'.


    add_abap_731 '  METHOD add_entity.'.
    add_abap_731 ''.
    add_abap_731 '    FIELD-SYMBOLS <ls_name> LIKE LINE OF g_named_entities.'.
    add_abap_731 '    DATA ls_named_entity    LIKE LINE OF g_named_entities.'.
    add_abap_731 ''.
    add_abap_731 '    IF can_be_referenced_by_name EQ true.'.
    add_abap_731 ''.
    add_abap_731 '      READ TABLE g_named_entities ASSIGNING <ls_name>'.
    add_abap_731 '            WITH TABLE KEY elementname = elementname name_group = name_group xname = name.'.
    add_replace.



    add_abap_740 '      g_named_entities = VALUE #( BASE g_named_entities ( elementname = elementname name_group = name_group xname = name id = g_processed_id ) ).'.

    " TBD Add here a clear statement
    " TBD do not use ls_ as prefix but only named_entity
    add_abap_731 '      ls_named_entity-elementname = elementname.'.
    add_abap_731 '      ls_named_entity-name_group  = name_group.'.
    add_abap_731 '      ls_named_entity-xname       = name.'.
    add_abap_731 '      ls_named_entity-id          = g_processed_id.'.
    add_abap_731 '      INSERT ls_named_entity INTO TABLE g_named_entities.'.
    add_replace.

    add_abap_740 '    g_elements_in_model = VALUE #( BASE g_elements_in_model ( id = g_processed_id'.
    add_abap_740 '                                                              is_named_entity = is_named_entity'.
    add_abap_740 '                                                              elementname = elementname ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only elements_in_model
    add_abap_731 '    DATA gs_elements_in_model LIKE LINE OF g_elements_in_model.'.
    add_abap_731 '    gs_elements_in_model-id = g_processed_id.'.
    add_abap_731 '    gs_elements_in_model-is_named_entity = is_named_entity.'.
    add_abap_731 '    gs_elements_in_model-elementname = elementname.'.
    add_abap_731 '    INSERT gs_elements_in_model INTO TABLE g_elements_in_model.'.
    add_replace.

    " METHOD make_mse.

    add_abap_740 '    DATA(is_first) = true.'.

    add_abap_731 '    DATA is_first TYPE boolean VALUE true.'.
    add_replace.

    add_abap_740 '    LOOP AT g_elements_in_model ASSIGNING FIELD-SYMBOL(<element_in_model>).'.

    add_abap_731 '    FIELD-SYMBOLS <element_in_model> LIKE LINE OF g_elements_in_model.'.
    add_abap_731 ''.
    add_abap_731 '    LOOP AT g_elements_in_model ASSIGNING <element_in_model>.'.
    add_replace.

    add_abap_740 '        mse_model = VALUE #( BASE mse_model ( mse_model_line ) ).'.

    add_abap_731 '        APPEND mse_model_line TO mse_model.'.

    add_replace.

    add_abap_740 '      LOOP AT g_attributes ASSIGNING FIELD-SYMBOL(<attribute>) WHERE id = <element_in_model>-id.'.

    add_abap_731 '      FIELD-SYMBOLS <attribute> LIKE LINE OF g_attributes.'.
    add_abap_731 '      LOOP AT g_attributes ASSIGNING <attribute> WHERE id = <element_in_model>-id.'.
    add_replace.

    add_abap_740 '        mse_model_line = VALUE #( ).'.

    add_abap_731 '        CLEAR mse_model_line.'.
    add_replace.

    " METHOD add_reference.

    c740 = |    READ TABLE g_named_entities ASSIGNING FIELD-SYMBOL(<named_entity>) WITH TABLE KEY elementname = elementname|. add_abap_740 c740.
    c740 = |                                                                                      name_group = name_group_of_reference|. add_abap_740 c740.
    c740 = |                                                                                      xname = name_of_reference.|. add_abap_740 c740.

    c731 = |    FIELD-SYMBOLS <named_entity> LIKE LINE OF g_named_entities.|. add_abap_731 c731.
    c731 = ||. add_abap_731 c731.
    c731 = |    READ TABLE g_named_entities ASSIGNING <named_entity> WITH TABLE KEY elementname = elementname|. add_abap_731 c731.
    c731 = |                                                                                      name_group = name_group_of_reference|. add_abap_731 c731.
    c731 = |                                                                                      xname = name_of_reference.|. add_abap_731 c731.
    add_replace.



    add_abap_740 '    g_attributes = VALUE #( BASE g_attributes ( id             = g_processed_id'.
    add_abap_740 '                                                attribute_id   = g_attribute_id'.
    add_abap_740 '                                                attribute_name = attribute_name'.
    add_abap_740 '                                                value_type     = reference_value'.
    add_abap_740 '                                                reference      = <named_entity>-id ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only attribute
    add_abap_731 '    DATA gs_attribute LIKE LINE OF g_attributes.'.
    add_abap_731 '    gs_attribute-id             = g_processed_id.'.
    add_abap_731 '    gs_attribute-attribute_id   = g_attribute_id.'.
    add_abap_731 '    gs_attribute-attribute_name = attribute_name.'.
    add_abap_731 '    gs_attribute-value_type     = reference_value.'.
    add_abap_731 '    gs_attribute-reference      = <named_entity>-id.'.
    add_abap_731 '    APPEND gs_attribute TO g_attributes.'.
    add_replace.

    " METHOD add_reference_by_id.

    add_abap_740 '    g_attributes = VALUE #( BASE g_attributes ( id             = g_processed_id'.
    add_abap_740 '                                                attribute_id   = g_attribute_id'.
    add_abap_740 '                                                attribute_name = attribute_name'.
    add_abap_740 '                                                value_type     = reference_value'.
    add_abap_740 '                                                reference      = reference_id ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only attribute
    add_abap_731 '    DATA gs_attribute LIKE LINE OF g_attributes.'.
    add_abap_731 '    gs_attribute-id             = g_processed_id.'.
    add_abap_731 '    gs_attribute-attribute_id   = g_attribute_id.'.
    add_abap_731 '    gs_attribute-attribute_name = attribute_name.'.
    add_abap_731 '    gs_attribute-value_type     = reference_value.'.
    add_abap_731 '    gs_attribute-reference      = reference_id.'.
    add_abap_731 '    APPEND gs_attribute TO g_attributes.'.
    add_replace.

    " METHOD add_string.

    add_abap_740 '    g_attributes = VALUE #( BASE g_attributes ( id             = g_processed_id'.
    add_abap_740 '                                                attribute_id   = g_attribute_id'.
    add_abap_740 '                                                attribute_name = attribute_name'.
    add_abap_740 '                                                value_type     = string_value'.
    add_abap_740 '                                                string         = string ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only attribute
    add_abap_731 '    DATA gs_attribute LIKE LINE OF g_attributes.'.
    add_abap_731 '    gs_attribute-id             = g_processed_id.'.
    add_abap_731 '    gs_attribute-attribute_id   = g_attribute_id.'.
    add_abap_731 '    gs_attribute-attribute_name = attribute_name.'.
    add_abap_731 '    gs_attribute-value_type     = string_value.'.
    add_abap_731 '    gs_attribute-string         = string.'.
    add_abap_731 '    APPEND gs_attribute TO g_attributes.'.
    add_replace.

    " METHOD add_boolean.

    add_abap_740 '    g_attributes = VALUE #( BASE g_attributes ( id             = g_processed_id'.
    add_abap_740 '                                                attribute_id   = g_attribute_id'.
    add_abap_740 '                                                attribute_name = attribute_name'.
    add_abap_740 '                                                value_type     = boolean_value'.
    add_abap_740 '                                                boolean        = is_true ) ).'.

    add_abap_731 '    DATA gs_attribute LIKE LINE OF g_attributes.'.
    add_abap_731 '    gs_attribute-id             = g_processed_id.'.
    add_abap_731 '    gs_attribute-attribute_id   = g_attribute_id.'.
    add_abap_731 '    gs_attribute-attribute_name = attribute_name.'.
    add_abap_731 '    gs_attribute-value_type     = boolean_value.'.
    add_abap_731 '    gs_attribute-boolean        = is_true.'.
    add_abap_731 '    APPEND gs_attribute TO g_attributes.'.
    add_replace.

    " CLASS cl_output_model
    add_abap_740 '    LOOP AT mse_model ASSIGNING FIELD-SYMBOL(<mse_model_line>).'.

    add_abap_731 '    FIELD-SYMBOLS <mse_model_line> LIKE LINE OF mse_model.'.
    add_abap_731 '    LOOP AT mse_model ASSIGNING <mse_model_line>.'.
    add_replace.

    " CLASS cl_famix_named_entity

    add_abap_740 '      EXPORTING VALUE(exists_already_with_id) TYPE i'.
    add_abap_740 '      RETURNING VALUE(id)                     TYPE i.'.

    add_abap_731 '      EXPORTING value(exists_already_with_id) TYPE i'.
    add_abap_731 '                value(id)                     TYPE i.'.
    add_replace.

    " CLASS cl_famix_named_entity

    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_740 '                                        is_named_entity = true'.
    add_abap_740 '                                        can_be_referenced_by_name = true'.
    add_abap_740 '                                        name_group = name_group'.
    add_abap_740 '                                        name = name'.
    add_abap_740 '                              IMPORTING exists_already_with_id = exists_already_with_id ).'.

    add_abap_731 '    g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_731 '                                        is_named_entity = true'.
    add_abap_731 '                                        can_be_referenced_by_name = true'.
    add_abap_731 '                                        name_group = name_group'.
    add_abap_731 '                                        name = name'.
    add_abap_731 '                              IMPORTING exists_already_with_id = exists_already_with_id'.
    add_abap_731 '                                        processed_id = id ).'.
    add_replace.

    " METHOD add.

    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_740 '                                        is_named_entity = true'.
    add_abap_740 '                                        can_be_referenced_by_name = false'.
    add_abap_740 '                                        name = name'.
    add_abap_740 '                              IMPORTING exists_already_with_id = exists_already_with_id ).'.

    add_abap_731 '    g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_731 '                                        is_named_entity = true'.
    add_abap_731 '                                        can_be_referenced_by_name = false'.
    add_abap_731 '                                        name = name'.
    add_abap_731 '                              IMPORTING exists_already_with_id = exists_already_with_id'.
    add_abap_731 '                                        processed_id = id ).'.
    add_replace.

    " CLASS cl_famix_attribute
    " METHOD add.
    add_abap_740 '    id = g_model->add_entity( elementname = g_elementname'.
    add_abap_740 '                              is_named_entity = true'.
    add_abap_740 '                              can_be_referenced_by_name = false'.
    add_abap_740 '                              name = name ).'.

    add_abap_731 '    g_model->add_entity('.
    add_abap_731 '               EXPORTING elementname = g_elementname'.
    add_abap_731 '                         is_named_entity = true'.
    add_abap_731 '                         can_be_referenced_by_name = false'.
    add_abap_731 '                         name = name'.
    add_abap_731 '               IMPORTING processed_id = id ).'.
    add_replace.

    " METHOD store_id.

    add_abap_740 '    g_attribute_ids = VALUE #( BASE g_attribute_ids ( id        = g_last_used_id'.
    add_abap_740 '                                                    class     = class'.
    add_abap_740 '                                                    attribute = attribute ) ).'.

    add_abap_731 '    DATA gs_attribute_id LIKE LINE OF g_attribute_ids. '.
    add_abap_731 '    gs_attribute_id-id = g_last_used_id.'.
    add_abap_731 '    gs_attribute_id-class = class.'.
    add_abap_731 '    gs_attribute_id-attribute = attribute.'.
    add_abap_731 '    INSERT gs_attribute_id INTO TABLE g_attribute_ids.'.
    add_replace.

    " METHOD get_id.

    add_abap_740 '    READ TABLE g_attribute_ids ASSIGNING FIELD-SYMBOL(<attribute_id>) WITH TABLE KEY class = class attribute = attribute.'.

    add_abap_731 '    FIELD-SYMBOLS <attribute_id> LIKE LINE OF g_attribute_ids.'.
    add_abap_731 ''.
    add_abap_731 '    READ TABLE g_attribute_ids ASSIGNING <attribute_id> WITH TABLE KEY class = class attribute = attribute.'.
    add_replace.

    " CLASS cl_famix_package
    " METHOD add.

    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_740 '                                        is_named_entity = true'.
    add_abap_740 '                                        can_be_referenced_by_name = true'.
    add_abap_740 '                                        name = name'.
    add_abap_740 '                              IMPORTING exists_already_with_id = exists_already_with_id ).'.

    add_abap_731 '    g_model->add_entity( EXPORTING elementname = g_elementname'.
    add_abap_731 '                                        is_named_entity = true'.
    add_abap_731 '                                        can_be_referenced_by_name = true'.
    add_abap_731 '                                        name = name'.
    add_abap_731 '                              IMPORTING exists_already_with_id = exists_already_with_id'.
    add_abap_731 '                                        processed_id = id ).'.
    add_replace.

    " CLASS cl_famix_module
    " METHOD add.

*    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname = g_elementname'.
*    add_abap_740 '                                        is_named_entity = true'.
*    add_abap_740 '                                        can_be_referenced_by_name = true'.
*    add_abap_740 '                                        name = name'.
*    add_abap_740 '                              IMPORTING exists_already_with_id = exists_already_with_id ).'.
*
*    add_abap_731 '    g_model->add_entity( EXPORTING elementname = g_elementname'.
*    add_abap_731 '                                   is_named_entity = true'.
*    add_abap_731 '                                   can_be_referenced_by_name = true'.
*    add_abap_731 '                                   name = name'.
*    add_abap_731 '                              IMPORTING exists_already_with_id = exists_already_with_id'.
*    add_abap_731 '                                   processed_id = id  ).'.
*    add_replace.
*
*    " CLASS cl_famix_method
*    " METHOD add.
*
*    add_abap_740 '    id = g_model->add_entity( elementname               = g_elementname'.
*    add_abap_740 '                              is_named_entity           = true'.
*    add_abap_740 '                              can_be_referenced_by_name = false'.
*    add_abap_740 '                              name = name ).'.
*
*    add_abap_731 '    g_model->add_entity('.
*    add_abap_731 '                    EXPORTING elementname               = g_elementname'.
*    add_abap_731 '                              is_named_entity           = true'.
*    add_abap_731 '                              can_be_referenced_by_name = false'.
*    add_abap_731 '                              name = name'.
*    add_abap_731 '                    IMPORTING processed_id = id ).'.
*    add_replace.

    " METHOD store_id.

    add_abap_740 '    g_method_ids = VALUE #( BASE g_method_ids ( id    = g_last_used_id'.
    add_abap_740 '                                                class = class method = method ) ).'.
    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only method
    add_abap_731 '    DATA gs_method_id LIKE LINE OF g_method_ids.'.
    add_abap_731 '    gs_method_id-id = g_last_used_id.'.
    add_abap_731 '    gs_method_id-class = class.'.
    add_abap_731 '    gs_method_id-method = method.'.
    add_abap_731 '    INSERT gs_method_id INTO TABLE g_method_ids.'.
    add_replace.

    " METHOD get_id.

    add_abap_740 '    READ TABLE g_method_ids ASSIGNING FIELD-SYMBOL(<method_id>) WITH TABLE KEY class = class'.
    add_abap_740 '                                                                                  method = method.'.

    add_abap_731 '    FIELD-SYMBOLS <method_id> LIKE LINE OF g_method_ids.'.
    add_abap_731 ''.
    add_abap_731 '    READ TABLE g_method_ids ASSIGNING <method_id> WITH TABLE KEY class = class'.
    add_abap_731 '                                                               method = method.'.
    add_replace.

    " CLASS cl_famix_association
    " METHOD add.

    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname               = g_elementname'.
    add_abap_740 '                                        is_named_entity           = false'.
    add_abap_740 '                                        can_be_referenced_by_name = false ).'.

    add_abap_731 '    g_model->add_entity( EXPORTING elementname               = g_elementname'.
    add_abap_731 '                                        is_named_entity           = false'.
    add_abap_731 '                                        can_be_referenced_by_name = false'.
    add_abap_731 '                                        IMPORTING processed_id = id ).'.
    add_replace.

    " CLASS cl_famix_access
    " METHOD set_accessor_variable_relation.

    add_abap_740 '    g_accessor_variable_ids = VALUE #( BASE g_accessor_variable_ids ( accessor_id = accessor_id variable_id = variable_id ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only accessor_id
    add_abap_731 '    DATA gs_accessor_id LIKE LINE OF g_accessor_variable_ids.'.
    add_abap_731 '    gs_accessor_id-accessor_id = accessor_id.'.
    add_abap_731 '    gs_accessor_id-variable_id = variable_id.'.
    add_abap_731 '    INSERT gs_accessor_id INTO TABLE g_accessor_variable_ids.'.
    add_replace.

    " CLASS cl_famix_invocation
    " METHOD set_invocation_by_reference.

    add_abap_740 '      g_sender_candidates = VALUE #( BASE g_sender_candidates ( sender_id = sender_id candidates_id = candidates_id ) ).'.

    " TBD Add here a clear statement
    " TBD do not use gs_ as prefix but only sender_candidate
    add_abap_731 '      DATA gs_sender_candidate LIKE LINE OF g_sender_candidates.'.
    add_abap_731 '      gs_sender_candidate-sender_id = sender_id.'.
    add_abap_731 '      gs_sender_candidate-candidates_id = candidates_id.'.
    add_abap_731 '      INSERT gs_sender_candidate INTO TABLE g_sender_candidates.'.
    add_replace.

    " CLASS cl_famix_custom_source_lang
    " METHOD add.

*    add_abap_740 '    id = g_model->add_entity( EXPORTING elementname = g_elementname'.
*    add_abap_740 '                                        is_named_entity = true'.
*    add_abap_740 '                                        can_be_referenced_by_name = true'.
*    add_abap_740 '                                        name = name'.
*    add_abap_740 '                              IMPORTING exists_already_with_id = exists_already_with_id ).'.
*
*    add_abap_731 '    g_model->add_entity( EXPORTING elementname = g_elementname'.
*    add_abap_731 '                                        is_named_entity = true'.
*    add_abap_731 '                                        can_be_referenced_by_name = true'.
*    add_abap_731 '                                        name = name'.
*    add_abap_731 '                              IMPORTING exists_already_with_id = exists_already_with_id'.
*    add_abap_731 '                                processed_id = id ).'.
*    add_replace.

    " CLASS cl_make_demo_model
    " METHOD make.

    add_abap_740 '    DATA(famix_namespace) = NEW cl_famix_namespace( model ).'.

    add_abap_731 '    DATA famix_namespace  TYPE REF TO cl_famix_namespace.'.
    add_abap_731 '    CREATE OBJECT famix_namespace EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(famix_package) = NEW cl_famix_package( model ).'.

    add_abap_731 '    DATA famix_package      TYPE REF TO cl_famix_package.'.
    add_abap_731 '    CREATE OBJECT famix_package EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(famix_class) = NEW cl_famix_class( model ).'.

    add_abap_731 '    DATA famix_class        TYPE REF TO cl_famix_class.'.
    add_abap_731 '    CREATE OBJECT famix_class EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(famix_method) = NEW cl_famix_method( model ).'.

    add_abap_731 '    DATA famix_method         TYPE REF TO cl_famix_method.'.
    add_abap_731 '    CREATE OBJECT famix_method EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(famix_attribute) = NEW cl_famix_attribute( model ).'.

    add_abap_731 '    DATA famix_attribute    TYPE REF TO cl_famix_attribute.'.
    add_abap_731 '    CREATE OBJECT famix_attribute EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(famix_inheritance) = NEW cl_famix_inheritance( model ).'.

    add_abap_731 '    DATA famix_inheritance  TYPE REF TO cl_famix_inheritance.'.
    add_abap_731 '    CREATE OBJECT famix_inheritance EXPORTING model = model.'.
    add_replace.

    " CLASS cl_sap_package
    " METHOD constructor.

    add_abap_740 '    g_famix_package = NEW cl_famix_package( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_package EXPORTING model = model.'.
    add_replace.

    " CLASS cl_sap_class

*    add_abap_740 '    METHODS add'.
*    add_abap_740 '      IMPORTING name                          TYPE clike'.
*    add_abap_740 '      EXPORTING VALUE(exists_already_with_id) TYPE i'.
*    add_abap_740 '      RETURNING VALUE(id)                     TYPE i.'.
*
*    add_abap_731 '    METHODS add'.
*    add_abap_731 '      IMPORTING name                          TYPE clike'.
*    add_abap_731 '      EXPORTING value(exists_already_with_id) TYPE i'.
*    add_abap_731 '                value(id)                     TYPE i.'.
*    add_replace.

    " CLASS cl_sap_class
    " METHOD constructor.

    add_abap_740 '    g_famix_class = NEW cl_famix_class( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_class EXPORTING model = model.'.
    add_replace.

    " METHOD add.

    c740 = |    id = g_famix_class->add( EXPORTING name_group             = ''|. add_abap_740 c740.
    c740 = |                                       name                   = name|. add_abap_740 c740.
    c740 = |                             IMPORTING exists_already_with_id = exists_already_with_id ).|. add_abap_740 c740.

    c731 = |    g_famix_class->add( EXPORTING name_group             = ''|. add_abap_731 c731.
    c731 = |                                       name                   = name|. add_abap_731 c731.
    c731 = |                             IMPORTING exists_already_with_id = exists_already_with_id|. add_abap_731 c731.
    c731 = |                                  id = id ).|. add_abap_731 c731.
    add_replace.

    " METHOD add.

    c740 = |    id = g_famix_class->add( EXPORTING name_group = program|. add_abap_740 c740.
    c740 = |                                             name       = name ).|. add_abap_740 c740.


    c731 = |    g_famix_class->add( EXPORTING name_group = program|. add_abap_731 c731.
    c731 = |                                  name       = name|. add_abap_731 c731.
    c731 = |                        IMPORTING id = id ).  |. add_abap_731 c731.
    add_replace.

    " CLASS cl_sap_attribute
    " METHOD constructor.

    add_abap_740 '    g_famix_attribute = NEW cl_famix_attribute( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_attribute EXPORTING model = model.'.
    add_replace.

    " CLASS cl_sap_method
    " METHOD constructor.

    add_abap_740 '    g_famix_method = NEW cl_famix_method( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_method EXPORTING model = model.'.
    add_replace.

    " METHOD add.

    c740 = |    id = g_famix_method->add( name = method ).|. add_abap_740 c740.

    c731 = |    g_famix_method->add( EXPORTING name = method IMPORTING id = id ).|. add_abap_731 c731.
    add_replace.

    " METHOD add_local_method.

    add_abap_740 '    id = g_famix_method->add( EXPORTING name_group = class_name " TBD Why name of class in name_group?'.
    add_abap_740 '                                        name       = method_name ).'.

    add_abap_731 '    g_famix_method->add( EXPORTING name_group = class_name " TBD Why name of class in name_group?'.
    add_abap_731 '                                        name       = method_name'.
    add_abap_731 '                                        IMPORTING id = id ).'.
    add_replace.

    " CLASS cl_sap_inheritance
    " METHOD constructor.

    add_abap_740 '    g_famix_inheritance = NEW cl_famix_inheritance( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_inheritance EXPORTING model = model.'.
    add_replace.

    " CLASS cl_sap_invocation
    " METHOD constructor.

    add_abap_740 '    g_famix_invocation = NEW cl_famix_invocation( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_invocation EXPORTING model = model.'.
    add_replace.

    " METHOD add_invocation.

    c740 = |    IF g_famix_invocation->is_new_invocation_to_candidate( sender_id     = using_method_id|. add_abap_740 c740.
    c740 = |                                                           candidates_id = used_method_id ).|. add_abap_740 c740.

    c731 = |    IF g_famix_invocation->is_new_invocation_to_candidate( sender_id     = using_method_id|. add_abap_731 c731.
    c731 = |                                                           candidates_id = used_method_id ) |. add_abap_731 c731.
    c731 = |       EQ true.|. add_abap_731 c731.
    add_replace.

    " CLASS cl_sap_access

    add_abap_740 '    g_famix_access = NEW cl_famix_access( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_access EXPORTING model = model.'.
    add_replace.

    " METHOD add_access.

    c740 = |    IF g_famix_access->is_new_access( accessor_id = using_method|. add_abap_740 c740.
    c740 = |                                      variable_id = used_attribute ).|. add_abap_740 c740.

    c731 = |    IF g_famix_access->is_new_access( accessor_id = using_method|. add_abap_731 c731.
    c731 = |                                      variable_id = used_attribute ) |. add_abap_731 c731.
    c731 = |       EQ true. |. add_abap_731 c731.
    add_replace.


    " CLASS cl_sap_program
    " METHOD constructor.

    add_abap_740 '    g_famix_module = NEW cl_famix_module( model = model ).'.

    add_abap_731 '    CREATE OBJECT g_famix_module EXPORTING model = model.'.
    add_replace.

    " METHOD add.

    c740 = |    id = g_famix_module->add( name = name ).|. add_abap_740 c740.

    c731 = |    g_famix_module->add( EXPORTING name = name IMPORTING id = id ).|. add_abap_731 c731.
    add_replace.

    " CLASS cl_extract_sap

    c740 = |    METHODS extract|. add_abap_740 c740.
    c740 = |      EXPORTING|. add_abap_740 c740.
    c740 = |                mse_model           TYPE cl_model=>lines_type|. add_abap_740 c740.
    c740 = |      RETURNING VALUE(nothing_done) TYPE bool.|. add_abap_740 c740.

    c731 = |    METHODS extract|. add_abap_731 c731.
    c731 = |      EXPORTING|. add_abap_731 c731.
    c731 = |                mse_model           TYPE cl_model=>lines_type|. add_abap_731 c731.
    c731 = |                value(nothing_done) TYPE bool. |. add_abap_731 c731.
    add_replace.

    " CLASS cl_ep_analyze_other_keyword
    " METHOD analyze.

    add_abap_740 '    g_info = VALUE #( ).'.

    add_abap_731 '    CLEAR g_info.'.
    add_replace.

    add_abap_740 '    READ TABLE g_sorted_tokens ASSIGNING FIELD-SYMBOL(<token>) WITH TABLE KEY index = statement-from.'.

    add_abap_731 '    FIELD-SYMBOLS <token> LIKE LINE OF g_sorted_tokens.'.
    add_abap_731 '    READ TABLE g_sorted_tokens ASSIGNING <token> WITH TABLE KEY index = statement-from.'.
    add_replace.

    add_abap_740 '      DATA(position_of_name) = statement-from + 1.'.

    add_abap_731 '      DATA position_of_name TYPE i.'.
    add_abap_731 '      position_of_name =  statement-from + 1.'.
    add_replace.


    add_abap_740 '              DATA(superclass_is_at) = sy-tabix + 2.'.

    add_abap_731 '              DATA superclass_is_at TYPE i.'.
    add_abap_731 '              superclass_is_at  = sy-tabix + 2.'.
    add_replace.

    add_abap_740 '              READ TABLE g_sorted_tokens ASSIGNING FIELD-SYMBOL(<ls_superclass_token>) WITH TABLE KEY index = superclass_is_at.'.

    add_abap_731 '              FIELD-SYMBOLS <ls_superclass_token> LIKE LINE OF g_sorted_tokens.'.
    add_abap_731 '              READ TABLE g_sorted_tokens ASSIGNING <ls_superclass_token> WITH TABLE KEY index = superclass_is_at.'.
    add_replace.

    " CLASS cl_program_analyzer
    " METHOD extract.

    add_abap_740 '    LOOP AT tokens ASSIGNING FIELD-SYMBOL(<ls_token_2>).'.

    add_abap_731 '    FIELD-SYMBOLS <ls_token_2> LIKE LINE OF tokens.'.
    add_abap_731 '    LOOP AT tokens ASSIGNING <ls_token_2>.'.

    add_replace.

    add_abap_740 '      sorted_tokens = VALUE #( BASE sorted_tokens ( index = sy-tabix'.
    add_abap_740 '                                                    str   = <ls_token_2>-str'.
    add_abap_740 '                                                    row   = <ls_token_2>-row'.
    add_abap_740 '                                                    col   = <ls_token_2>-col'.
    add_abap_740 '                                                    type  = <ls_token_2>-type ) ).'.

    add_abap_731 '      DATA token LIKE LINE OF sorted_tokens.'.
    add_abap_731 '      token-index = sy-tabix.'.
    add_abap_731 '      token-str   = <ls_token_2>-str.'.
    add_abap_731 '      token-row   = <ls_token_2>-row.'.
    add_abap_731 '      token-col   = <ls_token_2>-col.'.
    add_abap_731 '      token-type  = <ls_token_2>-type.'.
    add_abap_731 '      INSERT token INTO TABLE sorted_tokens.'.
    add_replace.

    add_abap_740 '    aok = NEW cl_ep_analyze_other_keyword( sorted_tokens = sorted_tokens ).'.

    add_abap_731 '    CREATE OBJECT aok EXPORTING sorted_tokens = sorted_tokens.'.
    add_replace.

    add_abap_740 '    LOOP AT statements ASSIGNING FIELD-SYMBOL(<statement>).'.

    add_abap_731 '    FIELD-SYMBOLS <statement> LIKE LINE OF statements.'.
    add_abap_731 '    LOOP AT statements ASSIGNING <statement>.'.
    add_replace.

    add_abap_740 '              classes_with_model_id = VALUE #( BASE classes_with_model_id ( actual_class_with_model_id ) ).'.

    "TBD here the 7.31 version appears to be more clear
    add_abap_731 '              INSERT actual_class_with_model_id INTO TABLE classes_with_model_id.'.
    add_replace.

    add_abap_740 '                inheritances = VALUE #( BASE inheritances ( subclass = actual_class_with_model_id-classname'.
    add_abap_740 '                                                                  superclass = aok->g_info-class_inherits_from ) ).'.

    " TBD add clear statement
    add_abap_731 '                DATA inheritance_2 LIKE LINE OF inheritances.'.
    add_abap_731 '                inheritance_2-subclass = actual_class_with_model_id-classname.'.
    add_abap_731 '                inheritance_2-superclass = aok->g_info-class_inherits_from.'.
    add_abap_731 '                INSERT inheritance_2 INTO TABLE inheritances.'.
    add_replace.

    add_abap_740 '              context-implementation_of_class = VALUE #( ).'.

    add_abap_731 '              CLEAR context-implementation_of_class.'.
    add_replace.

    add_abap_740 '                actual_method = VALUE #( classname = actual_class_with_model_id-classname'.
    add_abap_740 '                                         in_section = context-in_section ).'.

    " TBD add clear statement
    add_abap_731 '                actual_method-classname = actual_class_with_model_id-classname.'.
    add_abap_731 '                actual_method-in_section = context-in_section.'.
    add_replace.

    add_abap_740 '                actual_method = VALUE #( classname = actual_class_with_model_id-classname'.
    add_abap_740 '                                         in_section = context-in_section'.
    add_abap_740 '                                         instanciable = true ).'.

    " TBD add clear statement
    add_abap_731 '                actual_method-classname = actual_class_with_model_id-classname.'.
    add_abap_731 '                actual_method-in_section = context-in_section.'.
    add_abap_731 '                actual_method-instanciable = true.'.
    add_replace.

    add_abap_740 '              context-implementation_of_method = VALUE #( ).'.

    add_abap_731 '              CLEAR context-implementation_of_method.'.
    add_replace.

    add_abap_740 '        LOOP AT sorted_tokens ASSIGNING FIELD-SYMBOL(<token>) WHERE'.
    add_abap_740 '            index >= <statement>-from'.
    add_abap_740 '        AND index <= <statement>-to.'.

    add_abap_731 '        FIELD-SYMBOLS <token> LIKE LINE OF sorted_tokens.'.
    add_abap_731 '        LOOP AT sorted_tokens ASSIGNING <token> WHERE'.
    add_abap_731 '            index >= <statement>-from'.
    add_abap_731 '        AND index <= <statement>-to.'.
    add_replace.

    add_abap_740 '    DATA(sap_class) = NEW cl_sap_class( model ).'.

    add_abap_731 '    DATA sap_class TYPE REF TO cl_sap_class.'.
    add_abap_731 '    CREATE OBJECT sap_class EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    LOOP AT classes_with_model_id ASSIGNING FIELD-SYMBOL(<class>).'.

    add_abap_731 '    FIELD-SYMBOLS <class> LIKE LINE OF classes_with_model_id.'.
    add_abap_731 '    LOOP AT classes_with_model_id ASSIGNING <class>.'.
    add_replace.

    c740 = |      <class>-id_in_model = sap_class->add_local( EXPORTING program = program|. add_abap_740 c740.
    c740 = |                                                            name    = <class>-classname ).|. add_abap_740 c740.

    c731 = |      <class>-id_in_model = sap_class->add_local( program = program|. add_abap_731 c731.
    c731 = |                                                  name    = <class>-classname ).  |. add_abap_731 c731.
    add_replace.

    add_abap_740 '     DATA(sap_method) = NEW cl_sap_method( model ).'.

    add_abap_731 '    DATA sap_method TYPE REF TO cl_sap_method.'.
    add_abap_731 '    CREATE OBJECT sap_method EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    LOOP AT methods ASSIGNING FIELD-SYMBOL(<method>).'.

    add_abap_731 '    FIELD-SYMBOLS <method> LIKE LINE OF methods.'.
    add_abap_731 '    LOOP AT methods ASSIGNING <method>.'.
    add_replace.

    add_abap_740 '      READ TABLE classes_with_model_id ASSIGNING FIELD-SYMBOL(<class_2>) WITH TABLE KEY classname = <method>-classname.'.

    add_abap_731 '      FIELD-SYMBOLS <class_2> LIKE LINE OF classes_with_model_id.'.
    add_abap_731 '      READ TABLE classes_with_model_id ASSIGNING <class_2> WITH TABLE KEY classname = <method>-classname.'.
    add_replace.

    add_abap_740 '    DATA(sap_inheritance) = NEW cl_sap_inheritance( model ).'.

    add_abap_731 '    DATA sap_inheritance TYPE REF TO cl_sap_inheritance.'.
    add_abap_731 '    CREATE OBJECT sap_inheritance EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(model) = NEW cl_model( ).'.

    add_abap_731 '    DATA model            TYPE REF TO cl_model.'.
    add_abap_731 '    CREATE OBJECT model.'.
    add_replace.

    add_abap_740 '    DATA(sap_package) = NEW cl_sap_package( model ).'.

    add_abap_731 '    DATA sap_package     TYPE REF TO cl_sap_package.'.
    add_abap_731 '    CREATE OBJECT sap_package EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_program) = NEW cl_sap_program( model ).'.

    add_abap_731 '    DATA sap_program     TYPE REF TO cl_sap_program.'.
    add_abap_731 '    CREATE OBJECT sap_program EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_class) = NEW cl_sap_class( model ).'.

    add_abap_731 '    DATA sap_class       TYPE REF TO cl_sap_class.'.
    add_abap_731 '    CREATE OBJECT sap_class EXPORTING model = model.'.
    add_replace.


    add_abap_740 '    DATA(sap_inheritance) = NEW cl_sap_inheritance( model ).'.

    add_abap_731 '    DATA sap_inheritance TYPE REF TO cl_sap_inheritance.'.
    add_abap_731 '    CREATE OBJECT sap_inheritance EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_method) = NEW cl_sap_method( model ).'.

    add_abap_731 '    DATA sap_method      TYPE REF TO cl_sap_method.'.
    add_abap_731 '    CREATE OBJECT sap_method EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_attribute) = NEW cl_sap_attribute( model ).'.

    add_abap_731 '    DATA sap_attribute   TYPE REF TO cl_sap_attribute.'.
    add_abap_731 '    CREATE OBJECT sap_attribute EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_invocation) = NEW cl_sap_invocation( model ).'.

    add_abap_731 '    DATA sap_invocation  TYPE REF TO cl_sap_invocation.'.
    add_abap_731 '    CREATE OBJECT sap_invocation EXPORTING model = model.'.
    add_replace.

    add_abap_740 '    DATA(sap_access) = NEW cl_sap_access( model ).'.

    add_abap_731 '    DATA sap_access      TYPE REF TO cl_sap_access.'.
    add_abap_731 '    CREATE OBJECT sap_access EXPORTING model = model.'.
    add_replace.

    c740 = |   g_tadir_components_mapping = VALUE #( ( object = 'CLAS' component = 'GlobClass' )|. add_abap_740 c740.
    c740 = |                                          ( object = 'INTF' component = 'GlobIntf' )|. add_abap_740 c740.
    c740 = |                                          ( object = 'PROG' component = 'ABAPProgramm') ).|. add_abap_740 c740.

    " TBD add clear remove gs_

    add_abap_731 '    DATA gs_mapping TYPE map_tadir_component_type.'.
    c731 = |    gs_mapping-object = 'CLAS'.|. add_abap_731 c731.
    c731 = |    gs_mapping-component = 'GlobClass'. |. add_abap_731 c731.
    add_abap_731 '    INSERT gs_mapping INTO TABLE g_tadir_components_mapping.'.
    add_abap_731 ''.
    c731 = |    gs_mapping-object = 'INTF'.|.  add_abap_731 c731.
    c731 = |    gs_mapping-component = 'GlobIntf'.|.  add_abap_731 c731.
    add_abap_731 '    INSERT gs_mapping INTO TABLE g_tadir_components_mapping.'.
    add_abap_731 ''.
    c731 = |    gs_mapping-object = 'PROG'.|. add_abap_731 c731.
    c731 = |    gs_mapping-component = 'ABAPProgram'.|. add_abap_731 c731.
    add_abap_731 '    INSERT gs_mapping INTO TABLE g_tadir_components_mapping.'.
    add_replace.

    add_abap_740 '      DATA(select_by_top_package) = true.'.

    add_abap_731 '      DATA select_by_top_package TYPE boolean.'.
    add_abap_731 '      select_by_top_package = true.'.
    add_replace.

    add_abap_740 '      LOOP AT new_components_infos ASSIGNING FIELD-SYMBOL(<component_infos>).'.

    add_abap_731 '      FIELD-SYMBOLS <component_infos> LIKE LINE OF new_components_infos.'.
    add_abap_731 '      LOOP AT new_components_infos ASSIGNING <component_infos>.'.
    add_replace.

    add_abap_740 '        DATA(object) = g_tadir_components_mapping[ KEY comp component = <component_infos>-component ]-object.'.

    "TBD Check ls_ add assert statement or other as the read statement in 7.40 causes not catched class based exception
    add_abap_731 '        DATA object TYPE trobjtype.'.
    add_abap_731 '        DATA ls_tadir LIKE LINE OF g_tadir_components_mapping.'.
    add_abap_731 '        READ TABLE g_tadir_components_mapping'.
    add_abap_731 '              INTO ls_tadir'.
    add_abap_731 '              WITH KEY component  = <component_infos>-component.'.
    add_abap_731 '        object = ls_tadir-object.'.
    add_replace.

    add_abap_740 '        SELECT SINGLE devclass FROM tadir INTO @<component_infos>-package'.
    c740 = |          WHERE pgmid = 'R3TR'|. add_abap_740 c740.
    add_abap_740 '            AND object = @object'.
    add_abap_740 '            AND obj_name = @<component_infos>-component_name.'.

    add_abap_731 '        SELECT SINGLE devclass FROM tadir'.
    add_abap_731 '          INTO <component_infos>-package'.
    c731 = |         WHERE pgmid = 'R3TR'|. add_abap_731 c731.
    add_abap_731 '           AND object = object'.
    add_abap_731 '           AND obj_name = <component_infos>-component_name.'.
    add_replace.

    c740 = |      components_infos = VALUE #( ).|. add_abap_740 c740.

    c731 = |      CLEAR components_infos.|. add_abap_731 c731.
    add_replace.

    c740 = |      LOOP AT new_components_infos ASSIGNING FIELD-SYMBOL(<component_infos_2>).|. add_abap_740 c740.

    c731 = |      FIELD-SYMBOLS <component_infos_2> LIKE LINE OF new_components_infos.|. add_abap_731 c731.
    c731 = |      LOOP AT new_components_infos ASSIGNING <component_infos_2>.   |. add_abap_731 c731.
    add_replace.

    add_abap_740 '          components_infos = VALUE #( BASE components_infos ( <component_infos_2> ) ).'.

    add_abap_731 '          INSERT <component_infos_2> INTO TABLE components_infos.'.
    add_replace.

    " METHOD _determine_usages.

    c740 = |        SELECT * FROM wbcrossgt INTO TABLE @DATA(where_used_components) WHERE otype = 'ME' AND name = @where_used_name.|. add_abap_740 c740.

    add_abap_731 '        DATA where_used_components TYPE STANDARD TABLE OF wbcrossgt.'.
    c731 = |        SELECT * FROM wbcrossgt INTO TABLE where_used_components WHERE otype = 'ME' AND name = where_used_name.|. add_abap_731 c731.
    add_replace.

    c740 = |        SELECT * FROM wbcrossgt INTO TABLE @where_used_components WHERE otype = 'DA' AND name = @where_used_name.|. add_abap_740 c740.

    c731 = |        SELECT * FROM wbcrossgt INTO TABLE where_used_components WHERE otype = 'DA' AND name = where_used_name.|. add_abap_731 c731.
    add_replace.

    add_abap_740 '    LOOP AT where_used_components ASSIGNING FIELD-SYMBOL(<where_used_component>).'.

    add_abap_731 '    FIELD-SYMBOLS <where_used_component> LIKE LINE OF where_used_components.'.
    add_abap_731 '    LOOP AT where_used_components ASSIGNING <where_used_component>.'.
    add_replace.

    " Here a different coding is required for ABAP 7.31
    " TBD Check the validity

    add_abap_740 '      SELECT SINGLE * FROM ris_prog_tadir INTO @DATA(ris_prog_tadir_line) WHERE program_name = @<where_used_component>-include.'.

    " TBD This is wrong, this function does not return a sy-subrc with this declaration
    c731 = |      DATA ls_mtdkey TYPE seocpdkey.|. add_abap_731 c731.
    c731 = |      CALL FUNCTION 'SEO_METHOD_GET_NAME_BY_INCLUDE'|. add_abap_731 c731.
    add_abap_731 '        EXPORTING'.
    add_abap_731 '          progname = <where_used_component>-include'.
    add_abap_731 '        IMPORTING'.
    add_abap_731 '          mtdkey   = ls_mtdkey. '.
    add_replace.

    " TBD This is wrong, no check on whether a class is used

    c740 = |            CASE ris_prog_tadir_line-object_type.|. add_abap_740 c740.
    c740 = |          WHEN 'CLAS'.|. add_abap_740 c740.

    c731 = ||. add_abap_731 c731.
    add_replace.

    add_abap_740 '            IF ris_prog_tadir_line-method_name IS INITIAL.'.
    c740 = |              using_method = 'DUMMY'.|. add_abap_740 c740.
    add_abap_740 '            ELSE.'.
    add_abap_740 '              using_method = ris_prog_tadir_line-method_name.'.
    add_abap_740 '            ENDIF.'.

    add_abap_731 '        IF ls_mtdkey-cpdname IS INITIAL.'.
    c731 = |          using_method = 'DUMMY'.|. add_abap_731 c731.
    add_abap_731 '        ELSE.'.
    add_abap_731 '          using_method = ls_mtdkey-cpdname.'.
    add_abap_731 '        ENDIF. '.
    add_replace.

    c740 = |            DATA(using_method_id) = sap_method->get_id( class  = ris_prog_tadir_line-object_name|. add_abap_740 c740.
    c740 = |                                                        method = using_method ).|. add_abap_740 c740.

    c731 = |        DATA using_method_id TYPE i.|. add_abap_731 c731.
    c731 = |        using_method_id = sap_method->get_id( class  = ls_mtdkey-clsname|. add_abap_731 c731.
    c731 = |                                              method = using_method ).|. add_abap_731 c731.
    add_replace.

    c740 = |                sap_class->add( EXPORTING name = ris_prog_tadir_line-object_name|. add_abap_740 c740.
    c740 = |                                IMPORTING exists_already_with_id = DATA(exists_already_with_id) ).|. add_abap_740 c740.

    c731 = |            DATA exists_already_with_id TYPE i.|. add_abap_731 c731.
    c731 = |            sap_class->add( EXPORTING name = ls_mtdkey-cpdname|. add_abap_731 c731.
    c731 = |                            IMPORTING exists_already_with_id = exists_already_with_id ).|. add_abap_731 c731.
    add_replace.

    c740 = |                  new_components_infos = VALUE #( BASE new_components_infos (  component_name = ris_prog_tadir_line-object_name|. add_abap_740 c740.
    c740 = |                                                                               component   = g_tadir_components_mapping[ object = 'CLAS' ]-component ) ).|. add_abap_740 c740.

    " TBD Error, here a dump is to be raised if nothing is found in table g_tadir_components_mapping

    c731 = |              DATA new_components_info LIKE LINE OF new_components_infos.|. add_abap_731 c731.
    c731 = ||. add_abap_731 c731.
    c731 = |              DATA gs_tadir_comp_map LIKE LINE OF g_tadir_components_mapping.|. add_abap_731 c731.
    c731 = |              READ TABLE g_tadir_components_mapping INTO gs_tadir_comp_map WITH TABLE KEY object = 'CLAS'.|. add_abap_731 c731.
    c731 = |              IF sy-subrc = 0.|. add_abap_731 c731.
    c731 = |                new_components_info-component_name = ls_mtdkey-cpdname.|. add_abap_731 c731.
    c731 = |                new_components_info-component   = gs_tadir_comp_map-component .|. add_abap_731 c731.
    c731 = |                INSERT new_components_info INTO TABLE new_components_infos.|. add_abap_731 c731.
    c731 = |              ENDIF.|. add_abap_731 c731.
    add_replace.

    c740 = |              IF g_param_usage_outpack_groupd EQ false.|. add_abap_740 c740.
    c740 = |                using_method_id = sap_method->get_id( class  = ris_prog_tadir_line-object_name|. add_abap_740 c740.
    c740 = |                                                        method = using_method ).|. add_abap_740 c740.

    c731 = |          IF g_param_usage_outpack_groupd EQ false.|. add_abap_731 c731.
    c731 = |            using_method_id = sap_method->get_id( class  = ls_mtdkey-cpdname|. add_abap_731 c731.
    c731 = |                                                  method = using_method ).|. add_abap_731 c731.
    add_replace.

    c740 = |                  using_method_id = sap_method->add( EXPORTING class  = ris_prog_tadir_line-object_name|. add_abap_740 c740.
    c740 = |                                                               method = using_method ).|. add_abap_740 c740.

    c731 = |              using_method_id = sap_method->add( class  = ls_mtdkey-cpdname|. add_abap_731 c731.
    c731 = |                                                 method = using_method ).|. add_abap_731 c731.
    add_replace.

    c740 = |                  using_method_id = sap_method->add( EXPORTING class  = 'OTHER_SAP_CLASS'|. add_abap_740 c740.
    c740 = |                                                                 method = 'OTHER_SAP_METHOD'  ).|. add_abap_740 c740.

    c731 = |                  using_method_id = sap_method->add( class  = 'OTHER_SAP_CLASS'|. add_abap_731 c731.
    c731 = |                                                     method = 'OTHER_SAP_METHOD'  ).|. add_abap_731 c731.
    add_replace.

    c740 = |          WHEN OTHERS.|. add_abap_740 c740.
    c740 = |            " TBD Implement other usages|. add_abap_740 c740.
    c740 = |        ENDCASE.|. add_abap_740 c740.

    " TBD See above this is wrong

    c731 = |        " TBD Implement other usages|. add_abap_731 c731.
    add_replace.

    " METHOD _set_default_language.

    c740 = |    DATA(famix_custom_source_language) = NEW cl_famix_custom_source_lang( model ).|. add_abap_740 c740.

    c731 = |    DATA famix_custom_source_language TYPE REF TO cl_famix_custom_source_lang.|. add_abap_731 c731.
    c731 = |    CREATE OBJECT famix_custom_source_language EXPORTING model = model.|. add_abap_731 c731.
    add_replace.

    " METHOD _determine_packages_to_analyze.

    c740 = |    INSERT VALUE package_type( devclass = package_first-devclass ) INTO TABLE processed_packages.|. add_abap_740 c740.

    c731 = |    DATA processed_package LIKE LINE OF processed_packages.|. add_abap_731 c731.
    c731 = |    processed_package-devclass = package_first-devclass.|. add_abap_731 c731.
    c731 = |    INSERT processed_package INTO TABLE processed_packages.|. add_abap_731 c731.
    add_replace.

    c740 = |    temp_packages_to_search = VALUE #( ( devclass = g_parameter_package_to_analyze ) ).|. add_abap_740 c740.

    c731 = |    DATA temp_package_to_search LIKE LINE OF temp_packages_to_search.|. add_abap_731 c731.
    c731 = |    temp_package_to_search-devclass = g_parameter_package_to_analyze.|. add_abap_731 c731.
    c731 = |    INSERT temp_package_to_search INTO TABLE temp_packages_to_search.|. add_abap_731 c731.
    add_replace.

    c740 = |        SELECT devclass, parentcl FROM tdevc INTO TABLE @DATA(packages)|. add_abap_740 c740.
    c740 = |         FOR ALL ENTRIES IN @temp_packages_to_search WHERE parentcl = @temp_packages_to_search-devclass.   |. add_abap_740 c740.

    c731 = |        types: BEGIN OF abap_731_package_type,|. add_abap_731 c731.
    c731 = |          devclass TYPE tdevc-devclass,|. add_abap_731 c731.
    c731 = |          parentcl type tdevc-parentcl,|. add_abap_731 c731.
    c731 = |               END OF abap_731_package_type.|. add_abap_731 c731.
    c731 = |        data: packages type standard table of abap_731_package_type WITH DEFAULT KEY.|. add_abap_731 c731.
    c731 = |        SELECT devclass  parentcl FROM tdevc INTO TABLE packages|. add_abap_731 c731.
    c731 = |         FOR ALL ENTRIES IN temp_packages_to_search|. add_abap_731 c731.
    c731 = |          WHERE parentcl = temp_packages_to_search-devclass.   |. add_abap_731 c731.
    add_replace.

    c740 = |      temp_packages_to_search = VALUE #( ).|. add_abap_740 c740.

    c731 = |      CLEAR temp_packages_to_search.|. add_abap_731 c731.
    add_replace.

    c740 = |      LOOP AT packages INTO DATA(package).|. add_abap_740 c740.

    c731 = |      DATA package LIKE LINE OF packages. |. add_abap_731 c731.
    c731 = |      LOOP AT packages INTO package.      |. add_abap_731 c731.
    add_replace.

    c740 = |        INSERT VALUE package_type( devclass = package-devclass ) INTO TABLE processed_packages.|. add_abap_740 c740.

    " TBD Add clear statement

    c731 = |        processed_package-devclass = package-devclass.|. add_abap_731 c731.
    c731 = |        INSERT processed_package INTO TABLE processed_packages. |. add_abap_731 c731.
    add_replace.

    c740 = |          temp_packages_to_search = VALUE #( BASE temp_packages_to_search ( devclass = package-devclass ) ).|. add_abap_740 c740.
    " TBD Add clear statement
    c731 = |          temp_package_to_search-devclass = package-devclass.|. add_abap_731 c731.
    c731 = |          INSERT temp_package_to_search INTO TABLE temp_packages_to_search.    |. add_abap_731 c731.
    add_replace.


    c740 = |    MOVE-CORRESPONDING components_infos TO classes.                                        |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |    LOOP AT components_infos ASSIGNING FIELD-SYMBOL(<component_infos>).                    |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |      IF <component_infos>-component EQ 'GlobClass'                                        |. add_abap_740 c740.
    c740 = |      OR <component_infos>-component EQ 'GlobIntf'.                                        |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |        classes = VALUE #( BASE classes ( obj_name = <component_infos>-component_name ) ). |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |      ELSE.                                                                                |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |        programs = VALUE #( BASE programs ( program = <component_infos>-component_name ) ).|. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |      ENDIF.                                                                               |. add_abap_740 c740.
    c740 = |                                                                                           |. add_abap_740 c740.
    c740 = |    ENDLOOP.                                                                               |. add_abap_740 c740.

    c731 = |    DATA class LIKE LINE OF classes.                                                       |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |    FIELD-SYMBOLS <component_infos> LIKE LINE OF components_infos.                         |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |    LOOP AT components_infos ASSIGNING <component_infos>.                                  |. add_abap_731 c731.
    c731 = |      MOVE-CORRESPONDING <component_infos> TO class.                                       |. add_abap_731 c731.
    c731 = |      INSERT class INTO TABLE classes.                                                     |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |      IF <component_infos>-component EQ 'GlobClass'                                        |. add_abap_731 c731.
    c731 = |      OR <component_infos>-component EQ 'GlobIntf'.                                        |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |        class-obj_name = <component_infos>-component_name.                                 |. add_abap_731 c731.
    c731 = |        INSERT class INTO TABLE classes.                                                   |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |      ELSE.                                                                                |. add_abap_731 c731.
    c731 = |        DATA program LIKE LINE OF programs.                                                |. add_abap_731 c731.
    c731 = |        program-program = <component_infos>-component_name.                                |. add_abap_731 c731.
    c731 = |        INSERT program INTO TABLE programs.                                                |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |      ENDIF.                                                                               |. add_abap_731 c731.
    c731 = |                                                                                           |. add_abap_731 c731.
    c731 = |    ENDLOOP.                                                                               |. add_abap_731 c731.
    add_replace.

    c740 = |    LOOP AT programs ASSIGNING FIELD-SYMBOL(<program>).|. add_abap_740 c740.

    c731 = |    FIELD-SYMBOLS <program> LIKE LINE OF programs.     |. add_abap_731 c731.
    c731 = |    LOOP AT programs ASSIGNING <program>.              |. add_abap_731 c731.
    add_replace.

    c740 = |      DATA(module_reference) = sap_program->add( EXPORTING name = <program>-program ).|. add_abap_740 c740.

    c731 = |      DATA module_reference TYPE i.|. add_abap_731 c731.
    c731 = |      module_reference = sap_program->add( name = <program>-program ).|. add_abap_731 c731.
    add_replace.

    c740 = |      READ TABLE components_infos ASSIGNING FIELD-SYMBOL(<component_infos>) WITH TABLE KEY component = 'ABAPProgramm' component_name = <program>-program.|. add_abap_740 c740.

    c731 = |      FIELD-SYMBOLS <component_infos> LIKE LINE OF components_infos.  |. add_abap_731 c731.
    c731 = |      READ TABLE components_infos ASSIGNING <component_infos>|. add_abap_731 c731.
    c731 = |            WITH TABLE KEY component = 'ABAPProgram'|. add_abap_731 c731.
    c731 = |                           component_name = <program>-program.|. add_abap_731 c731.
    add_replace.

    c740 = |        DATA(program_analyzer) = NEW cl_program_analyzer( ).  |. add_abap_740 c740.

    c731 = |        DATA program_analyzer TYPE REF TO cl_program_analyzer.|. add_abap_731 c731.
    c731 = |        CREATE OBJECT program_analyzer.                       |. add_abap_731 c731.
    add_replace.

    " METHOD _add_classes_to_model.

    c740 = |    LOOP AT existing_classes INTO DATA(existing_class).|. add_abap_740 c740.

    c731 = |    DATA existing_class LIKE LINE OF existing_classes.|. add_abap_731 c731.
    c731 = |    LOOP AT existing_classes INTO existing_class.|. add_abap_731 c731.
    add_replace.

    c740 = |      READ TABLE components_infos ASSIGNING FIELD-SYMBOL(<component_infos>) WITH TABLE KEY component = 'GlobClass' component_name = existing_class-class.|. add_abap_740 c740.

    c731 = |      FIELD-SYMBOLS <component_infos> LIKE LINE OF components_infos.                                                                                     |. add_abap_731 c731.
    c731 = |      READ TABLE components_infos ASSIGNING <component_infos> WITH TABLE KEY component = 'GlobClass' component_name = existing_class-class.              |. add_abap_731 c731.
    add_replace.

    " METHOD _determine_inheritances_betwee.

    c740 = |      SELECT clsname, refclsname, reltype FROM seometarel INTO CORRESPONDING FIELDS OF TABLE @inheritances|. add_abap_740 c740.
    c740 = |        FOR ALL ENTRIES IN @existing_classes WHERE clsname = @existing_classes-class|. add_abap_740 c740.
    c740 = |                                               AND version = 1.    |. add_abap_740 c740.

    c731 = |      SELECT clsname refclsname reltype FROM seometarel INTO CORRESPONDING FIELDS OF TABLE inheritances|. add_abap_731 c731.
    c731 = |        FOR ALL ENTRIES IN existing_classes WHERE clsname = existing_classes-class|. add_abap_731 c731.
    c731 = |                                               AND version = 1.      |. add_abap_731 c731.
    add_replace.

    c740 = |    LOOP AT inheritances INTO DATA(inheritance).|. add_abap_740 c740.

    c731 = |    DATA inheritance LIKE LINE OF inheritances. |. add_abap_731 c731.
    c731 = |    LOOP AT inheritances INTO inheritance.      |. add_abap_731 c731.
    add_replace.

    c740 = |    LOOP AT inheritances INTO DATA(inheritance_2).|. add_abap_740 c740.

    c731 = |    DATA inheritance_2 LIKE LINE OF inheritances. |. add_abap_731 c731.
    c731 = |    LOOP AT inheritances INTO inheritance_2.      |. add_abap_731 c731.
    add_replace.

    " METHOD _determine_class_components.

    c740 = |      SELECT clsname, cmpname, cmptype FROM seocompo INTO TABLE @class_components|. add_abap_740 c740.
    c740 = |        FOR ALL ENTRIES IN @existing_classes|. add_abap_740 c740.
    c740 = |        WHERE|. add_abap_740 c740.
    c740 = |          clsname = @existing_classes-class.|. add_abap_740 c740.

    c731 = |      SELECT clsname cmpname cmptype FROM seocompo INTO TABLE class_components|. add_abap_731 c731.
    c731 = |        FOR ALL ENTRIES IN existing_classes|. add_abap_731 c731.
    c731 = |        WHERE|. add_abap_731 c731.
    c731 = |          clsname = existing_classes-class.|. add_abap_731 c731.
    add_replace.

    " METHOD _add_to_class_components_to_mo.

    c740 = |    LOOP AT class_components INTO DATA(class_component).|. add_abap_740 c740.

    c731 = |    DATA class_component LIKE LINE OF class_components. |. add_abap_731 c731.
    c731 = |    LOOP AT class_components INTO class_component.      |. add_abap_731 c731.
    add_replace.

    c740 = |          DATA(existing_id) = sap_attribute->get_id( EXPORTING class     = class_component-clsname|. add_abap_740 c740.
    c740 = |                                                               attribute = class_component-cmpname ).|. add_abap_740 c740.

    c731 = |          DATA existing_id TYPE i.|. add_abap_731 c731.
    c731 = |          existing_id =  sap_attribute->get_id( class     = class_component-clsname|. add_abap_731 c731.
    c731 = |                                                attribute = class_component-cmpname ).|. add_abap_731 c731.
    add_replace.

    " METHOD _determine_usage_of_methods.

    c740 = |          DATA(used_id) = sap_method->get_id( class  = class_component-clsname|. add_abap_740 c740.
    c740 = |                                                method = class_component-cmpname ).|. add_abap_740 c740.

    c731 = |          DATA used_id TYPE i.|. add_abap_731 c731.
    c731 = |          used_id = sap_method->get_id( class  = class_component-clsname|. add_abap_731 c731.
    c731 = |                                        method = class_component-cmpname ).|. add_abap_731 c731.
    add_replace.

    " METHOD _read_all_classes.

    c740 = |      SELECT clsname AS class FROM seoclass INTO TABLE @existing_classes FOR ALL ENTRIES IN @classes|. add_abap_740 c740.
    c740 = |        WHERE|. add_abap_740 c740.
    c740 = |          clsname = @classes-obj_name.|. add_abap_740 c740.

    c731 = |      SELECT clsname AS class FROM seoclass INTO TABLE existing_classes FOR ALL ENTRIES IN classes|. add_abap_731 c731.
    c731 = |        WHERE|. add_abap_731 c731.
    c731 = |          clsname = classes-obj_name.|. add_abap_731 c731.
    add_replace.

    " METHOD _select_requested_components.

    c740 = |      SELECT SINGLE devclass, parentcl FROM tdevc INTO @first_package WHERE devclass = @package_to_analyze.|. add_abap_740 c740.

    c731 = |      SELECT SINGLE devclass parentcl FROM tdevc INTO first_package WHERE devclass = package_to_analyze.|. add_abap_731 c731.
    add_replace.

    c740 = |          SELECT obj_name, object, devclass FROM tadir INTO @DATA(tadir_component) FOR ALL ENTRIES IN @processed_packages|. add_abap_740 c740.
    c740 = |            WHERE pgmid = 'R3TR'|. add_abap_740 c740.
    c740 = |              AND object = @object|. add_abap_740 c740.
    c740 = |              AND devclass = @processed_packages-devclass.|. add_abap_740 c740.

    c731 = |          DATA: BEGIN OF tadir_component,|. add_abap_731 c731.
    c731 = |                   obj_name LIKE tadir-obj_name,|. add_abap_731 c731.
    c731 = |                   object   LIKE tadir-object,|. add_abap_731 c731.
    c731 = |                   devclass LIKE tadir-devclass,|. add_abap_731 c731.
    c731 = |                END OF tadir_component.|. add_abap_731 c731.
    c731 = |          SELECT obj_name object devclass FROM tadir INTO tadir_component FOR ALL ENTRIES IN processed_packages|. add_abap_731 c731.
    c731 = |            WHERE pgmid = 'R3TR'|. add_abap_731 c731.
    c731 = |              AND object = object|. add_abap_731 c731.
    c731 = |              AND devclass = processed_packages-devclass.|. add_abap_731 c731.
    add_replace.

    only_once. " Because otherwise the data declarations would be doubled
    c740 = |            components_infos = VALUE #( BASE components_infos ( component = g_tadir_components_mapping[ object = tadir_component-object ]-component|. add_abap_740 c740.
    c740 = |                                                                component_name = tadir_component-obj_name|. add_abap_740 c740.
    c740 = |                                                                package = tadir_component-devclass ) ).|. add_abap_740 c740.

    " TBD Assert is missed, because the exception if no data is found is not added to 7.31 coding
    " Add clear statement
    c731 = |            DATA component_info LIKE LINE OF components_infos.|. add_abap_731 c731.
    c731 = |            DATA map LIKE LINE OF g_tadir_components_mapping.|. add_abap_731 c731.
    c731 = |            |. add_abap_731 c731.
    c731 = |            READ TABLE g_tadir_components_mapping INTO map WITH TABLE KEY object = tadir_component-object.|. add_abap_731 c731.
    c731 = |            IF sy-subrc = 0.|. add_abap_731 c731.
    c731 = ||. add_abap_731 c731.
    c731 = |              component_info-component = map-component.|. add_abap_731 c731.
    c731 = |            ENDIF.|. add_abap_731 c731.
    c731 = |            component_info-component_name = tadir_component-obj_name.|. add_abap_731 c731.
    c731 = |            component_info-package = tadir_component-devclass.|. add_abap_731 c731.
    c731 = |            INSERT component_info INTO TABLE components_infos.|. add_abap_731 c731.
    add_replace.

    c740 = |          SELECT obj_name, object, devclass FROM tadir INTO @tadir_component|. add_abap_740 c740.
    c740 = |            WHERE pgmid = 'R3TR'|. add_abap_740 c740.
    c740 = |              AND object = @object|. add_abap_740 c740.
    c740 = |              AND obj_name IN @s_compsn|. add_abap_740 c740.
    c740 = |              AND devclass IN @s_pack.|. add_abap_740 c740.

    c731 = |          SELECT obj_name object devclass FROM tadir INTO tadir_component|. add_abap_731 c731.
    c731 = |            WHERE pgmid = 'R3TR'|. add_abap_731 c731.
    c731 = |              AND object = object|. add_abap_731 c731.
    c731 = |              AND obj_name IN s_compsn|. add_abap_731 c731.
    c731 = |              AND devclass IN s_pack.|. add_abap_731 c731.
    add_replace.

    c740 = |            components_infos = VALUE #( BASE components_infos ( component = g_tadir_components_mapping[ object = tadir_component-object ]-component|. add_abap_740 c740.
    c740 = |                                                                component_name = tadir_component-obj_name|. add_abap_740 c740.
    c740 = |                                                                package = tadir_component-devclass ) ).  |. add_abap_740 c740.

    " TBD Assert is missed, because the exception if no data is found is not added to 7.31 coding
    " Add clear statement
    c731 = |            READ TABLE g_tadir_components_mapping INTO map WITH TABLE KEY object = tadir_component-object.|. add_abap_731 c731.
    c731 = |            IF sy-subrc = 0.|. add_abap_731 c731.
    c731 = ||. add_abap_731 c731.
    c731 = |              component_info-component = map-component.|. add_abap_731 c731.
    c731 = |            ENDIF.|. add_abap_731 c731.
    c731 = |            component_info-component_name = tadir_component-obj_name.|. add_abap_731 c731.
    c731 = |            component_info-package = tadir_component-devclass.|. add_abap_731 c731.
    c731 = |            INSERT component_info INTO TABLE components_infos. |. add_abap_731 c731.
    add_replace.

    " START-OF-SELECTION.

    c740 = |    DATA(sap_extractor) = NEW cl_extract_sap( ).|. add_abap_740 c740.

    c731 = |    DATA sap_extractor TYPE REF TO cl_extract_sap.|. add_abap_731 c731.
    c731 = |    CREATE OBJECT sap_extractor.|. add_abap_731 c731.
    add_replace.

    c740 = |    DATA(nothing_done) = sap_extractor->extract( IMPORTING mse_model = mse_model ).  |. add_abap_740 c740.

    c731 = |    DATA nothing_done TYPE boolean.|. add_abap_731 c731.
    c731 = |    sap_extractor->extract( IMPORTING mse_model    = mse_model|. add_abap_731 c731.
    c731 = |                                      nothing_done = nothing_done ).|. add_abap_731 c731.
    add_replace.

    c740 = |  DATA(model_outputer) = NEW cl_output_model( ).|. add_abap_740 c740.

    c731 = |  DATA model_outputer TYPE REF TO cl_output_model.|. add_abap_731 c731.
    c731 = |  CREATE OBJECT model_outputer.|. add_abap_731 c731.
    add_replace.






  ENDMETHOD.

  METHOD get_conversion.

    replaces = g_replaces.

  ENDMETHOD.

ENDCLASS.

CLASS cl_convert DEFINITION.
  PUBLIC SECTION.
    DATA: g_conversion TYPE REF TO cl_conversion.
    METHODS constructor.
    METHODS do
      CHANGING source TYPE stringtable.
  PRIVATE SECTION.

    METHODS _read_first_line_to_compare
      IMPORTING
        replace           TYPE cl_conversion=>replace_type
      EXPORTING
        code_index        TYPE i
        abap_740_codeline TYPE cl_conversion=>codeline_type.
ENDCLASS.

CLASS cl_convert IMPLEMENTATION.

  METHOD constructor.

    CREATE OBJECT g_conversion.

  ENDMETHOD.

  METHOD do.

    DATA: replaces    TYPE g_conversion->replaces_type,
          replace     TYPE g_conversion->replace_type,
          codeline    TYPE g_conversion->codeline_type,
          "! All code lines to be replaced
          codelines   TYPE g_conversion->codelines_type,
          "! The code lines after processing a scan for a single replacement
          codelines_2 TYPE g_conversion->codelines_type,
          "! A temporary list for code lines where at least part of the lines fit to the actual searched replace
          codelines_3 TYPE g_conversion->codelines_type,
          line        TYPE string,
          code_index  TYPE i.

    replaces = g_conversion->get_conversion( ).

    LOOP AT source INTO line.

      codeline-code = line.
      codeline-condensed = line.
      CONDENSE codeline-condensed.
      TRANSLATE codeline-condensed TO UPPER CASE.
      APPEND codeline TO codelines.

    ENDLOOP.

    " The replace is now done the following way.

    " general, compared are always the condensed lines, replaced is the not condensed line.

    " For each entry in table replaces:

    " Loop over code lines and transfer line by line into codelines_2
    "   but only if a line is not equal to the first line in replace-abap_740

    "   if it is equal it will be transfered to codelines_3
    "   in that case all lines of replace-abap_740 have to be found
    "   if not all lines are equal to replace-abap_740, codelines_3 is appended to codelines_2 and scan is proceeded normally
    "   if all lines are equal, replace-abap_730 is appended to codelines_2 and codelines_3 is cleared than scan is proceeded normally


    LOOP AT replaces ASSIGNING FIELD-SYMBOL(<replace>).

      DATA: abap_740_codeline TYPE g_conversion->codeline_type,
            line_is_equal     TYPE bool,
            "! True if comparison for a replacement started. This is the case if the first line was found in the code.
            first_line_equal  TYPE bool.

      _read_first_line_to_compare( EXPORTING replace           = <replace>
                                   IMPORTING code_index        = code_index
                                             abap_740_codeline = abap_740_codeline ).

      codelines_2 = VALUE #( ).

      LOOP AT codelines INTO codeline.

        IF first_line_equal EQ true.
          ADD 1 TO code_index.
          READ TABLE <replace>-abap_740 INTO abap_740_codeline INDEX code_index.
          IF sy-subrc EQ 0. " Row is found

          ELSEIF sy-subrc EQ 4. " Row is not found
            codelines_2 = VALUE #( BASE codelines_2 ( LINES OF <replace>-abap_731 ) ).
            ADD 1 TO <replace>-replaced.
            codelines_3 = VALUE #( ).
            first_line_equal = false.

            _read_first_line_to_compare( EXPORTING replace           = <replace>
                                         IMPORTING code_index        = code_index
                                                   abap_740_codeline = abap_740_codeline ).


          ELSE. " Occurs if comparing statement or binary search is used, not supported here
            ASSERT 1 = 2.
          ENDIF.
        ENDIF.

        IF codeline-condensed EQ abap_740_codeline-condensed
           and not ( <replace>-replaced >= 1 and <replace>-only_once eq true ).

          IF code_index EQ 1.
            first_line_equal = true.
            codelines_3 = VALUE #( ( codeline ) ).
          ELSE.
            codelines_3 = VALUE #( BASE codelines_3 ( codeline ) ).
          ENDIF.

          line_is_equal = true.
        ELSE.

          IF first_line_equal EQ false.

            codelines_2 = VALUE #( BASE codelines_2 ( codeline ) ).

          ELSE.

            codelines_2 = VALUE #( BASE codelines_2 ( LINES OF codelines_3 ) ). " Add the remembered lines
            codelines_2 = VALUE #( BASE codelines_2 ( codeline ) ). " Add the actual line
            codelines_3 = VALUE #( ).
            first_line_equal = false.

            _read_first_line_to_compare( EXPORTING replace           = <replace>
                                         IMPORTING code_index        = code_index
                                                   abap_740_codeline = abap_740_codeline ).

          ENDIF.

          line_is_equal = false.
        ENDIF.

        " TBD finalize logic

      ENDLOOP.

      codelines_2 = VALUE #( BASE codelines_2 ( LINES OF codelines_3 ) ).

      codelines = codelines_2.

    ENDLOOP.

    source = VALUE #( ).

    LOOP AT codelines INTO codeline.

      APPEND codeline-code TO source.

    ENDLOOP.

    " List replaces

    LOOP AT replaces INTO replace.
      WRITE: / replace-replace_id.
      IF replace-replaced EQ 0.
        FORMAT COLOR COL_TOTAL.
      ELSE.
        FORMAT COLOR COL_BACKGROUND.
      ENDIF.
      WRITE: replace-replaced, replace-abap_740[ 1 ]-code.
      FORMAT COLOR COL_BACKGROUND.
    ENDLOOP.

  ENDMETHOD.


  METHOD _read_first_line_to_compare.

    code_index = 1.
    READ TABLE replace-abap_740 INTO abap_740_codeline INDEX code_index.
    ASSERT sy-subrc EQ 0. " Row has to be found

  ENDMETHOD.

ENDCLASS.


START-OF-SELECTION.
  DATA(read) = NEW cl_read( ).
  DATA(convert) = NEW cl_convert( ).
  DATA(download) = NEW cl_download( ).

  DATA(source) = read->do( ).
  convert->do( CHANGING source = source ).
  download->do( source = source ).