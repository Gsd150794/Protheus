/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço  |23/08/2024| Chamado 45226 - Inclusão de campos B. ICMS ST An e ICMS ST Ant
Igor Melgaço  |04/09/2024| Chamado 45226 - Inclusão de campos B. ICMS e P. ICMS e Vr ICMS
Antonio Neves |23/09/2024| Chamado 48559 - Inclusão de campos A.ICMS ST An e E retirar calculo automatico vlr icms
=========================================================================================================================================================
Analista         - Programador       - Inicio     - Envio      - Chamado - Motivo da Alteração
---------------------------------------------------------------------------------------------------------------------------------------------------------
Antonio Ramos    - Igor Melgaço      - 02/10/2025 - 10/10/2025 - 52240   - Ajuste para gravação dos valores de ICMS/PIS/COFINS conforme a digitação do campo.
=========================================================================================================================================================
*/

#Include "FWMBROWSE.CH"
#Include "FWMVCDEF.CH"
#Include "TOTVS.ch"

Static _aSF1  := {}
Static _aSD1P := {}
Static _aSD1I := {}

/*
===============================================================================================================================
Programa----------: MFIS010
Autor-------------: Igor Melgaço
Data da Criacao---: 23/12/2022
Descrição---------: Acertos Fiscais Italac para nota de Entrada. Chamado: 43865 
Parametros--------: 
Retorno-----------:  
===============================================================================================================================
*/ 
User Function MFIS010(_cFiltro As Character)

    Local _oBrowse := Nil As Object
    Default _cFiltro := "" 

    _oBrowse := FWMBrowse():New()
    _oBrowse:SetAlias("SF1")
    _oBrowse:SetMenuDef( 'MFIS010' )
    _oBrowse:SetOnlyFields( { 'F1_FILIAL' , 'F1_DOC' , 'F1_SERIE' , 'F1_FORNECE', 'F1_LOJA' , 'F1_I_NFORN' , 'F1_EMISSAO' , 'F1_DTDIGIT' } )
    _oBrowse:SetDescription("Acertos Fiscais Italac (Notas de Entrada)")
    _oBrowse:SetFilterDefault( _cFiltro )

    _oBrowse:Activate()

Return

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição automática do menu via MVC
Parametros--------: 
Retorno-----------: aRotina - Definições do menu principal da Rotina.
===============================================================================================================================
*/
Static Function MenuDef() As Array

    Local _aRotina	:= {} As Array

    ADD OPTION _aRotina Title 'Acertar'	                Action 'VIEWDEF.MFIS010'	OPERATION MODEL_OPERATION_UPDATE ACCESS 0
    ADD OPTION _aRotina Title 'Visualizar'	            Action 'VIEWDEF.MFIS010'	OPERATION MODEL_OPERATION_VIEW ACCESS 0
        
Return( _aRotina )

/*
===============================================================================================================================
Programa----------: ModelDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição do Modelo de Dados do MVC
Parametros--------: 
Retorno-----------: _oModel - Objeto do modelo de dados do MVC 
===============================================================================================================================
*/ 
Static Function ModelDef()

    Local _oModel As Object
    Local _oStruSF1  := FWFormStruct(1,"SF1",{ |x| AllTrim(x) $ 'F1_FILIAL,F1_DOC,F1_SERIE,F1_FORNECE,F1_I_NFORN,F1_LOJA,F1_EMISSAO,F1_DTDIGIT,F1_BASIMP5,F1_VALIMP5,F1_BASIMP6,F1_VALIMP6,F1_TIPO,F1_ESPECIE,F1_BASEICM,F1_VALICM' } ) As Object
    Local _oStruSD1E := FWFormStruct(1,"SD1",{ |x| AllTrim(x) $ 'D1_COD,D1_ITEM,D1_CF,D1_TES,D1_DIFAL,D1_BASEDES,D1_ICMSCOM,D1_CLASFIS,D1_BASEICM,D1_PICM,D1_VALICM' } ) As Object
    Local _oStruSD1F := FWFormStruct(1,"SD1",{ |x| AllTrim(x) $ 'D1_COD,D1_ITEM,D1_BASIMP6,D1_ALQIMP6,D1_VALIMP6,D1_BASIMP5,D1_ALQIMP5,D1_VALIMP5' } ) As Object
    Local _bPosValidacao := {||(U_MFIS010LOG())} As Block
    Local _bCommit   := {||U_MFIS010VAL()} As Block
    Local _aSD1Rel   := {} As Array

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_BICMS' , ;             // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_BASEICM } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_VICMS' , ;             // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_VALICM } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_BASPIS' , ;             // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_BASIMP6 } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_VRPIS' , ;              // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_VALIMP6 } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_BASCOF' , ;             // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_BASIMP5 } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'F1_VRCOF' , ;              // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SF1->F1_VALIMP5 } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 

    //==================
    //Guia Federais
    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_CODIGO' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           15 , ;                      // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_COD } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_DESCRI' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           50 , ;                      // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           {||} , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC") } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_BASPIS' , ;             // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_BASIMP6 } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_PERPIS' , ;             // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           8 , ;                       // [05] N Tamanho do campo
           4 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_ALQIMP6 } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_VRPIS' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_VALIMP6 } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 


    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_BASCOF' , ;             // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_BASIMP5 } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_PERCOF' , ;             // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           8 , ;                       // [05] N Tamanho do campo
           4 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_ALQIMP5 } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1F:AddField( ;
        AllTrim('') , ;             // [01] C Titulo do campo
        AllTrim('') , ;             // [02] C ToolTip do campo
        'D1_VRCOF' , ;              // [03] C identificador (ID) do Field
        'N' , ;                     // [04] C Tipo do campo
        14 , ;                      // [05] N Tamanho do campo
        2 , ;                       // [06] N Decimal do campo
        NIL , ;                     // [07] B Code-block de validação do campo
        NIL , ;                     // [08] B Code-block de validação When do campo
        NIL , ;                     // [09] A Lista de valores permitido do campo
        NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
        { || SD1->D1_VALIMP5 } , ;  // [11] B Code-block de inicializacao do campo
        NIL , ;                     // [12] L Indica se trata de um campo chave
        NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
        .T. )                       // [14] L Indica se o campo é virtual 
    //=========================
    //Guia Estaduais
    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_CODIGO' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           15 , ;                      // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_COD } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_DESCRI' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           50 , ;                      // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           {||} , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || Posicione("SB1",1,xFilial("SB1")+SD1->D1_COD,"B1_DESC") } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_BICMS' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_BASEICM } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_PICMS' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           7 , ;                      // [05] N Tamanho do campo
           3 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_PICM  } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 


    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_VICMS' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_VALICM  } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 


    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_BASDES' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_BASEDES } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_BASNDES' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_BASNDES } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 


    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_ALQNDES' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           6 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_ALQNDES} , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_ICMNDES' , ;              // [03] C identificador (ID) do Field
           'N' , ;                     // [04] C Tipo do campo
           14 , ;                      // [05] N Tamanho do campo
           2 , ;                       // [06] N Decimal do campo
           NIL , ;                     // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_ICMNDES} , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .T. )                       // [14] L Indica se o campo é virtual 


    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_CLASSEF' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           3 , ;                       // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           {||U_MFIS010WHE('D1_CLASSEF')} , ;      // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_CLASFIS } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_TRIBUT' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           3 , ;                       // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           {||U_MFIS010WHE('D1_TRIBUT')} , ;      // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_TES } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSD1E:AddField( ;
           AllTrim('') , ;             // [01] C Titulo do campo
           AllTrim('') , ;             // [02] C ToolTip do campo
           'D1_CODFISC' , ;             // [03] C identificador (ID) do Field
           'C' , ;                     // [04] C Tipo do campo
           5 , ;                       // [05] N Tamanho do campo
           0 , ;                       // [06] N Decimal do campo
           {||U_MFIS010WHE('D1_CODFISC')} , ;      // [07] B Code-block de validação do campo
           NIL , ;                     // [08] B Code-block de validação When do campo
           NIL , ;                     // [09] A Lista de valores permitido do campo
           NIL , ;                     // [10] L Indica se o campo tem preenchimento obrigatório
           { || SD1->D1_CF } , ;  // [11] B Code-block de inicializacao do campo
           NIL , ;                     // [12] L Indica se trata de um campo chave
           NIL , ;                     // [13] L Indica se o campo pode receber valor em uma operação de update.
           .F. )                       // [14] L Indica se o campo é virtual 

    _oStruSF1:SetProperty("F1_FILIAL" , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_DOC"    , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_SERIE"  , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_FORNECE", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_LOJA"   , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_I_NFORN", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_EMISSAO", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_DTDIGIT", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_BASIMP5", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_VALIMP5", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_BASIMP6", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_VALIMP6", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_ESPECIE", MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_TIPO"   , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_BASPIS" , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_VRPIS"  , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_BASCOF" , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_VRCOF"  , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_BICMS"  , MODEL_FIELD_WHEN, {|| .F.})
    _oStruSF1:SetProperty("F1_VICMS"  , MODEL_FIELD_WHEN, {|| .F.})

    _oStruSD1E:SetProperty("D1_CF"       , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_TRIBUT"   , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_DIFAL"    , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_BASEDES"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_BASNDES"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_ALQNDES"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_ICMNDES"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_BICMS"    , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_PICMS"    , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_VICMS"    , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })

    _oStruSD1E:SetProperty("D1_ICMSCOM"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_CLASSEF"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })
    _oStruSD1E:SetProperty("D1_CODFISC"  , MODEL_FIELD_WHEN, {|| U_MFIS009ALT("EST") })


    _aGatAux := FwStruTrigger( 'D1_BASCOF'	, 'D1_VRCOF'	, 'U_MFIS010IMP("COF")' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_PERCOF'	, 'D1_VRCOF'	, 'U_MFIS010IMP("COF")' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_VRCOF'	, 'D1_VALIMP5'	, 'M->D1_VRCOF' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_BASPIS'	, 'D1_VRPIS'	, 'U_MFIS010IMP("PIS")' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_PERPIS'	, 'D1_VRPIS'	, 'U_MFIS010IMP("PIS")' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_VRPIS'	, 'D1_VALIMP6'	, 'M->D1_VRPIS' , .F. )
    _oStruSD1F:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_BASDES'	, 'D1_BASEDES'	, 'U_MFIS010BAS()'      , .F. )
    _oStruSD1E:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_BICMS'	, 'D1_VICMS'	, 'U_MFIS010IMP("ICM")' , .F. )
    _oStruSD1E:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_PICMS'	, 'D1_VICMS'	, 'U_MFIS010IMP("ICM")' , .F. )
    _oStruSD1E:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _aGatAux := FwStruTrigger( 'D1_VICMS'	, 'D1_VALICM'	, 'U_MFIS010X("ICM")' , .F. )
    _oStruSD1E:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

    _oModel := MPFormModel():New('MFIS010M' ,  /*bPreValidacao*/ , _bPosValidacao , _bCommit /*bCommit*/ , /*bCancel*/)

    _oModel:AddFields('SF1CAB', /*cOwner*/ ,_oStruSF1,/*bPreValidacao*/ , /*bPosValidacao*/ , /*bCarga*/)
    _oModel:AddGrid('SD1DETAILE','SF1CAB'   ,_oStruSD1E,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)
    _oModel:AddGrid('SD1DETAILF','SF1CAB'   ,_oStruSD1F,/*bLinePre*/, /*bLinePost*/, /*bPreVal*/,/*bPosVal*/, /*bLoad*/)

    aAdd(_aSD1Rel, {'D1_FILIAL' , 'SF1CAB.F1_FILIAL' } )
    aAdd(_aSD1Rel, {'D1_SERIE'  , 'SF1CAB.F1_SERIE'  } )
    aAdd(_aSD1Rel, {'D1_DOC'    , 'SF1CAB.F1_DOC'    } )
    aAdd(_aSD1Rel, {'D1_FORNECE', 'SF1CAB.F1_FORNECE'} )
    aAdd(_aSD1Rel, {'D1_LOJA'   , 'SF1CAB.F1_LOJA'   } )

    _oModel:SetRelation('SD1DETAILE', _aSD1Rel, SD1->(IndexKey(1)))
    _oModel:SetRelation('SD1DETAILF', _aSD1Rel, SD1->(IndexKey(1)))

    _oModel:SetPrimaryKey( {"F1_FILIAL","F1_DOC","F1_SERIE","F1_FORNECE","F1_LOJA" } )
    _oModel:SetDescription("Acertos Fiscais Italac (Nota de Entrada)")

    _oModel:GetModel( 'SD1DETAILE' ):SetNoInsertLine( .T. )
    _oModel:GetModel( 'SD1DETAILE' ):SetNoDeleteLine( .T. )

    _oModel:GetModel( 'SD1DETAILF' ):SetNoInsertLine( .T. )
    _oModel:GetModel( 'SD1DETAILF' ):SetNoDeleteLine( .T. )

    _oModel:SetVldActivate( { |_oModel| U_MFIS010FIS(_oModel) } )

Return _oModel

/*
===============================================================================================================================
Programa----------: ViewDef
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de definição da View do MVC
Parametros--------: 
Retorno-----------: _oView - Objeto de exibição do MVC  
===============================================================================================================================
*/ 
Static Function ViewDef()

    Local _oStruSF1  := FWFormStruct(2,"SF1",{ |x| AllTrim(x) $ 'F1_FILIAL,F1_DOC,F1_SERIE,F1_FORNECE,F1_I_NFORN,F1_LOJA,F1_EMISSAO,F1_DTDIGIT,F1_BASIMP5,F1_VALIMP5,F1_BASIMP6,F1_VALIMP6,F1_TIPO,F1_ESPECIE,F1_BASEICM,F1_VALICM' } ) As Object
    Local _oStruSD1E := FWFormStruct(2,"SD1",{ |x| AllTrim(x) $ 'D1_COD,D1_ITEM,D1_CF,D1_TES,D1_DIFAL,D1_BASEDES,D1_ICMSCOM,D1_CLASFIS,D1_BASEICM,D1_PICM,D1_VALICM' } ) As Object
    Local _oStruSD1F := FWFormStruct(2,"SD1",{ |x| AllTrim(x) $ 'D1_COD,D1_ITEM,D1_BASIMP6,D1_ALQIMP6,D1_VALIMP6,D1_BASIMP5,D1_ALQIMP5,D1_VALIMP5' } ) As Object
    Local _oModel    := FWLoadModel("MFIS010") As Object
    Local _oView     := Nil As Object

    _oStruSF1:AddField( ;                       // Ord. Tipo Desc.
        'F1_BICMS'                     , ;     // [01] C   Nome do Campo
        "88"                            , ;     // [02] C   Ordem
        AllTrim( 'Base ICMS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSF1:AddField( ;                       // Ord. Tipo Desc.
        'F1_VICMS'                     , ;     // [01] C   Nome do Campo
        "89"                            , ;     // [02] C   Ordem
        AllTrim( 'Valor ICMS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 999.99'                     , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 


    _oStruSF1:AddField( ;                       // Ord. Tipo Desc.
        'F1_BASPIS'                     , ;     // [01] C   Nome do Campo
        "90"                            , ;     // [02] C   Ordem
        AllTrim( 'Base PIS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSF1:AddField( ;                      // Ord. Tipo Desc.
        'F1_VRPIS'                      , ;     // [01] C   Nome do Campo
        "91"                            , ;     // [02] C   Ordem
        AllTrim( 'Valor PIS'    )       , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSF1:AddField( ;                       // Ord. Tipo Desc.
        'F1_BASCOF'                     , ;     // [01] C   Nome do Campo
        "92"                            , ;     // [02] C   Ordem
        AllTrim( 'Base COFINS'    )     , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSF1:AddField( ;                      // Ord. Tipo Desc.
        'F1_VRCOF'                      , ;     // [01] C   Nome do Campo
        "93"                            , ;     // [02] C   Ordem
        AllTrim( 'Valor COFINS'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    //==========================
    //Guia Federais
    _oStruSD1F:AddField( ;                       // Ord. Tipo Desc.
        'D1_CODIGO'                     , ;     // [01] C   Nome do Campo
        "01"                            , ;     // [02] C   Ordem
        AllTrim( 'Produto'    )         , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                       // Ord. Tipo Desc.
        'D1_DESCRI'                     , ;     // [01] C   Nome do Campo
        "02"                            , ;     // [02] C   Ordem
        AllTrim( 'Descricao'    )         , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                       // Ord. Tipo Desc.
        'D1_BASPIS'                     , ;     // [01] C   Nome do Campo
        "06"                            , ;     // [02] C   Ordem
        AllTrim( 'Base PIS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                      // Ord. Tipo Desc.
        'D1_PERPIS'                     , ;     // [01] C   Nome do Campo
        "07"                            , ;     // [02] C   Ordem
        AllTrim( '% PIS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 999.9999'                   , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                      // Ord. Tipo Desc.
        'D1_VRPIS'                      , ;     // [01] C   Nome do Campo
        "08"                            , ;     // [02] C   Ordem
        AllTrim( 'Valor PIS'    )       , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                       // Ord. Tipo Desc.
        'D1_BASCOF'                     , ;     // [01] C   Nome do Campo
        "09"                            , ;     // [02] C   Ordem
        AllTrim( 'Base COFINS'    )     , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                      // Ord. Tipo Desc.
        'D1_PERCOF'                     , ;     // [01] C   Nome do Campo
        "10"                            , ;     // [02] C   Ordem
        AllTrim( '% COFINS'    )        , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 999.9999'                   , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1F:AddField( ;                      // Ord. Tipo Desc.
        'D1_VRCOF'                      , ;     // [01] C   Nome do Campo
        "11"                            , ;     // [02] C   Ordem
        AllTrim( 'Valor COFINS'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("FED")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 
 
     //==========================
    //Guia Estaduais
    _oStruSD1E:AddField( ;                       // Ord. Tipo Desc.
        'D1_CODIGO'                     , ;     // [01] C   Nome do Campo
        "01"                            , ;     // [02] C   Ordem
        AllTrim( 'Produto'    )         , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                       // Ord. Tipo Desc.
        'D1_DESCRI'                     , ;     // [01] C   Nome do Campo
        "02"                            , ;     // [02] C   Ordem
        AllTrim( 'Descricao'    )         , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        .F.                             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_BICMS'                      , ;     // [01] C   Nome do Campo
        "93"                            , ;     // [02] C   Ordem
        AllTrim( 'Base ICMS'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_PICMS'                      , ;     // [01] C   Nome do Campo
        "94"                            , ;     // [02] C   Ordem
        AllTrim( 'Perc. ICMS'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 999.999'                     , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_VICMS'                      , ;     // [01] C   Nome do Campo
        "95"                            , ;     // [02] C   Ordem
        AllTrim( 'Vr ICMS'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 


    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_BASDES'                      , ;     // [01] C   Nome do Campo
        "96"                            , ;     // [02] C   Ordem
        AllTrim( 'Base Destino'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

     _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_BASNDES'                      , ;     // [01] C   Nome do Campo
        "97"                            , ;     // [02] C   Ordem
        AllTrim( 'B. Icms ST An'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 
 
    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_ALQNDES'                      , ;     // [01] C   Nome do Campo
        "98"                            , ;     // [02] C   Ordem
        AllTrim( 'A.ICMS ST An'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 999,999.99'                 , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 


    _oStruSD1E:AddField( ;                      // Ord. Tipo Desc.
        'D1_ICMNDES'                      , ;     // [01] C   Nome do Campo
        "99"                            , ;     // [02] C   Ordem
        AllTrim( 'ICMS ST Ant'    )    , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@E 99,999,999,999.99'          , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 
 


     _oStruSD1E:AddField( ;                       // Ord. Tipo Desc.
        'D1_CLASSEF'                    , ;     // [01] C   Nome do Campo
        "06"                            , ;     // [02] C   Ordem
        AllTrim( 'Sit.Tribut.'    )     , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        ''                              , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                       // Ord. Tipo Desc.
        'D1_TRIBUT'                     , ;     // [01] C   Nome do Campo
        "07"                            , ;     // [02] C   Ordem
        AllTrim( 'Tipo Entrada'    )      , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'N'                             , ;     // [06] C   Tipo do campo
        '@!'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        'SF4'                           , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 

    _oStruSD1E:AddField( ;                       // Ord. Tipo Desc.
        'D1_CODFISC'                     , ;     // [01] C   Nome do Campo
        "08"                            , ;     // [02] C   Ordem
        AllTrim( 'Cod Fiscal'    )      , ;     // [03] C   Titulo do campo
        AllTrim( '' )                   , ;     // [04] C   Descricao do campo
        { 'Legenda' }                   , ;     // [05] A   Array com Help
        'C'                             , ;     // [06] C   Tipo do campo
        '@9'                            , ;     // [07] C   Picture
        NIL                             , ;     // [08] B   Bloco de Picture Var
        '13'                            , ;     // [09] C   Consulta F3
        U_MFIS009ALT("EST")             , ;     // [10] L   Indica se o campo é alteravel
        NIL                             , ;     // [11] C   Pasta do campo
        NIL                             , ;     // [12] C   Agrupamento do campo
        NIL                             , ;     // [13] A   Lista de valores permitido do campo (Combo)
        NIL                             , ;     // [14] N   Tamanho maximo da maior opção do combo
        NIL                             , ;     // [15] C   Inicializador de Browse
        .T.                             , ;     // [16] L   Indica se o campo é virtual
        NIL                             , ;     // [17] C   Picture Variavel
        NIL                             )       // [18] L   Indica pulo de linha após o campo 


    _oStruSF1:RemoveField('F1_BASEICM')
    _oStruSF1:RemoveField('F1_VALICM')

    _oStruSD1E:RemoveField('D1_CLASFIS')
    _oStruSD1E:RemoveField('D1_TES')
    _oStruSD1E:RemoveField('D1_CF')
    _oStruSD1E:RemoveField('D1_COD')
    _oStruSD1E:RemoveField('D1_BASEICM')
    _oStruSD1E:RemoveField('D1_PICM')
    _oStruSD1E:RemoveField('D1_VALICM')

    _oStruSD1F:RemoveField('D1_COD')

    _oView := FWFormView():New()
    _oView:SetModel(_oModel)

    _oView:AddField("VIEW_SF1",_oStruSF1,"SF1CAB"   ,,)
    _oView:AddGrid('VIEW_SD1I' ,_oStruSD1E,'SD1DETAILE',,)
    _oView:AddGrid('VIEW_SD1P' ,_oStruSD1F,'SD1DETAILF',,)

    //Setando o dimensionamento de tamanho
    _oView:CreateHorizontalBox('CABEC',50)
    _oView:CreateHorizontalBox('DETAIL',50)

    _oView:CreateFolder('FOLDER1','DETAIL')

    _oView:AddSheet('FOLDER1','SHEET1','Infomações Estaduais')
    _oView:AddSheet('FOLDER1','SHEET2','Informações Federais')

    _oView:CreateHorizontalBox('SHEET1_BOX',100,,,'FOLDER1','SHEET1')
    _oView:CreateHorizontalBox('SHEET2_BOX',100,,,'FOLDER1','SHEET2')

    //Amarrando a view com as box
    _oView:SetOwnerView('VIEW_SF1','CABEC')
    _oView:SetOwnerView('VIEW_SD1I','SHEET1_BOX')
    _oView:SetOwnerView('VIEW_SD1P','SHEET2_BOX')

    //Habilitando títuloMFIS010CON
    _oView:EnableTitleView('VIEW_SF1',"Cabeçalho da Nota")
    _oView:EnableTitleView('VIEW_SD1I',"Itens da Nota")
    _oView:EnableTitleView('VIEW_SD1P',"Itens da Nota")

    _oView:AddUserButton( 'Log de Alterações do Corpo da Nota', 'CLIPS', {|_oView| U_MFIS010CON("CAB")} )
    _oView:AddUserButton( 'Log de Alterações do Item da Nota', 'CLIPS', {|_oView| U_MFIS010CON("ITEM")} )

    //Tratativa padrão para fechar a tela
    _oView:SetCloseOnOk({||.T.})

Return _oView

/*
===============================================================================================================================
Programa----------: MFIS010VAL
Autor-------------: Igor Melgaço
Data da Criacao---: 08/06/2021
Descrição---------: Rotina de Validação
Parametros--------: 
Retorno-----------: _lReturn
===============================================================================================================================
*/ 
User Function MFIS010VAL() As Logical

    Local _cOpcLog := 'A' As Character
    Local _oModel  := FWModelActive() As Object
    Local _cChave  := (_oModel:GetValue( 'SF1CAB','F1_FILIAL')+_oModel:GetValue( 'SF1CAB','F1_DOC')+_oModel:GetValue( 'SF1CAB','F1_SERIE')+_oModel:GetValue( 'SF1CAB','F1_FORNECE')+_oModel:GetValue( 'SF1CAB','F1_LOJA')) As Character
    Local _cCodUsr := RetCodUsr() As Character
    Local _dDatLog := Date() As Date
    Local _cHorLog := Time() As Character
    Local i        := 0 As Numeric
    Local lRet     := .T. As Logical
    Local cData    := DToC(SF1->F1_DTDIGIT) As Character
    Local cDoc     := SF1->F1_DOC As Character
    Local cSerie   := SF1->F1_SERIE As Character
    Local cFor     := SF1->F1_FORNECE As Character
    Local cLoja    := SF1->F1_LOJA As Character
    Local lRotAut  := .T. As Logical
    Local aParam   := array(11) As Array
    Local lExec    := .F. As Logical

    lRet := FWFormCommit( _oModel )

    If lRet
        Begin Sequence

            // Inicia processamento com base nas filiais do parâmetro.
            u_itconout( 'Abrindo o ambiente para filial 01...' )
        
            aParam[1] := cData //Data Inicial
            aParam[2] := cData //Data Final
            aParam[3] := 1      // 1-Entrada 2-Saída 3-Ambos
            aParam[4] := cDoc   // Nota Fiscal Incial
            aParam[5] := cDoc   // Nota Fiscal Final
            aParam[6] := cSerie // Série Incial
            aParam[7] := cSerie // Série Final
            aParam[8] := cFor   // Cli/For Inicial
            aParam[9] := cFor   // Cli/For Final
            aParam[10] := cLoja // Loja Incial
            aParam[11] := cLoja // Loja Final

            FWMsgRun(,{||  lExec := MATA930(lRotAut,aParam) },'Aguarde processamento...','Reprocessando Livro Fiscal...')

        End Sequence

        DBSelectArea("SF1")
        DBSelectArea("SD1")

        U_ITGrvLog( _aSF1 , "SF1" , 1 , _cChave , _cOpcLog , _cCodUsr , _dDatLog , _cHorLog )
        
        For i := 1 To Len(_aSD1P)
            U_ITGrvLog( _aSD1P[i,2]  , "SD1" , 1 , _aSD1P[i,1] , _cOpcLog , _cCodUsr , _dDatLog , _cHorLog )
        Next

        For i := 1 To Len(_aSD1I)
            U_ITGrvLog( _aSD1I[i,2]  , "SD1" , 1 , _aSD1I[i,1] , _cOpcLog , _cCodUsr , _dDatLog , _cHorLog )
        Next
    EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: MFIS010IMP
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Gatilho que calcula o Valor de Pis e Cofins
Parametros--------: cCampo: Pis ou Cofins
Retorno-----------: Vr do Imposto
===============================================================================================================================
*/
User Function MFIS010IMP(cCampo As Character) As Numeric

    Local _oModel   := FWModelActive() As Object
    Local _oModelDET := Nil As Object
    Local _nBase    := 0 As Numeric
    Local _nPerc    := 0 As Numeric
    Local _nTotBase := 0 As Numeric

    Local _nTotVr   := 0 As Numeric
    Local i := 0 As Numeric
    Local _nImp := 0 As Numeric
    Local _nLinPos := 0 As Numeric
    //Campos na Tela
    //Cabeçalho
    Local cCpoGetBC := "" As Character
    Local cCpoGetVC := "" As Character
    //Itens
    Local cCpoGetB := "" As Character
    Local cCpoGetP := "" As Character

    //Campos na Tabela onde serão gravados no Commit
    //Cabeçalho
    Local cCpoLoadBC := "" As Character
    Local cCpoLoadVC := "" As Character
    //Itens
    Local cCpoLoadB := "" As Character
    Local cCpoLoadP := "" As Character
    Local cCpoLoadV := "" As Character

    Local cSD1Detalhe := "" As Character

    If cCampo == "PIS"
       cSD1Detalhe := 'SD1DETAILF'
       
       //Cabeçalho
       cCpoGetBC := "F1_BASPIS"
       cCpoGetVC := "F1_VRPIS"

       cCpoLoadBC := "F1_BASIMP6"
       cCpoLoadVC := "F1_VALIMP6"
       //Itens
       cCpoGetB := "D1_BASPIS"
       cCpoGetP := "D1_PERPIS"

       cCpoLoadB := "D1_BASIMP6"
       cCpoLoadP := "D1_ALQIMP6"
       cCpoLoadV := "D1_VALIMP6"

    ElseIf cCampo == "COF"
       cSD1Detalhe := 'SD1DETAILF'

       //Cabeçalho
       cCpoGetBC := "F1_BASCOF"
       cCpoGetVC := "F1_VRCOF"

       cCpoLoadBC := "F1_BASIMP5"
       cCpoLoadVC := "F1_VALIMP5"
       //Itens
       cCpoGetB := "D1_BASCOF"
       cCpoGetP := "D1_PERCOF"

       cCpoLoadB := "D1_BASIMP5"
       cCpoLoadP := "D1_ALQIMP5"
       cCpoLoadV := "D1_VALIMP5"

    ElseIf cCampo == "ICM"
       cSD1Detalhe := 'SD1DETAILE'
       //Cabeçalho
       cCpoGetBC := "F1_BICMS"
       cCpoGetVC := "F1_VICMS"

       cCpoLoadBC := "F1_BASEICM"
       cCpoLoadVC := "F1_VALICM"
       //Itens
       cCpoGetB := "D1_BICMS"
       cCpoGetP := "D1_PICMS"

       cCpoLoadB := "D1_BASEICM"
       cCpoLoadP := "D1_PICM"
       cCpoLoadV := "D1_VALICM"
    EndIf

    _oModelDET := _oModel:GetModel(cSD1Detalhe)

    _nBase	:= _oModel:GetValue( cSD1Detalhe , cCpoGetB )
    _nPerc	:= _oModel:GetValue( cSD1Detalhe , cCpoGetP )
    _nImp   := _nPerc / 100 * _nBase

    _oModel:LoadValue( cSD1Detalhe,cCpoLoadB,_nBase)
    _oModel:LoadValue( cSD1Detalhe,cCpoLoadP,_nPerc)
    _oModel:LoadValue( cSD1Detalhe,cCpoLoadV,_nImp)

    _nQtdLin	:= _oModelDET:Length()
    _nLinPos    := _oModelDET:GetLine() 

    For i := 1 to _nQtdLin
        _oModelDET:GoLine( i )
        _nTotBase += _oModel:GetValue( cSD1Detalhe , cCpoGetB )
        _nTotVr   += _oModel:GetValue( cSD1Detalhe , cCpoLoadV )
    Next

    _oModel:LoadValue( 'SF1CAB',cCpoGetBC,_nTotBase )
    _oModel:LoadValue( 'SF1CAB',cCpoGetVC,_nTotVr   )
    _oModel:LoadValue( 'SF1CAB',cCpoLoadBC,_nTotBase)
    _oModel:LoadValue( 'SF1CAB',cCpoLoadVC,_nTotVr  )

    _oModelDET:GoLine( _nLinPos ) 

Return _nImp


/*
===============================================================================================================================
Programa----------: MFIS010X
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Gatilho que calcula o Valor de Pis e Cofins
Parametros--------: cCampo: Pis / Cofins / ICMS
Retorno-----------: Vr do Imposto
===============================================================================================================================
*/
User Function MFIS010X(cCampo As Character) As Numeric
    Local _oModel   := FWModelActive() As Object
    Local _oModelDET := Nil As Object
    Local _nTotBase := 0 As Numeric
    Local _nTotVr   := 0 As Numeric
    Local i := 0 As Numeric
    Local _nImp := 0 As Numeric
    Local _nLinPos := 0 As Numeric
    //Campos na Tela
    //Cabeçalho
    Local cCpoGetBC := "" As Character
    Local cCpoGetVC := "" As Character
    //Itens
    Local cCpoGetB := "" As Character
    Local cCpoGetP := "" As Character

    //Campos na Tabela onde serão gravados no Commit
    //Cabeçalho
    Local cCpoLoadBC := "" As Character
    Local cCpoLoadVC := "" As Character
    //Itens
    Local cCpoLoadB := "" As Character
    Local cCpoLoadP := "" As Character
    Local cCpoLoadV := "" As Character

    Local cSD1Detalhe := "" As Character

    If cCampo == "PIS"
       cSD1Detalhe := 'SD1DETAILF'
       
       //Cabeçalho
       cCpoGetBC := "F1_BASPIS"
       cCpoGetVC := "F1_VRPIS"

       cCpoLoadBC := "F1_BASIMP6"
       cCpoLoadVC := "F1_VALIMP6"
       //Itens
       cCpoGetB := "D1_BASPIS"
       cCpoGetP := "D1_PERPIS"
       cCpoGetV := "D1_VRPIS"

       cCpoLoadB := "D1_BASIMP6"
       cCpoLoadP := "D1_ALQIMP6"
       cCpoLoadV := "D1_VALIMP6"

    ElseIf cCampo == "COF"
       cSD1Detalhe := 'SD1DETAILF'

       //Cabeçalho
       cCpoGetBC := "F1_BASCOF"
       cCpoGetVC := "F1_VRCOF"

       cCpoLoadBC := "F1_BASIMP5"
       cCpoLoadVC := "F1_VALIMP5"
       //Itens
       cCpoGetB := "D1_BASCOF"
       cCpoGetP := "D1_PERCOF"
       cCpoGetV := "D1_VRCOF"

       cCpoLoadB := "D1_BASIMP5"
       cCpoLoadP := "D1_ALQIMP5"
       cCpoLoadV := "D1_VALIMP5"

    ElseIf cCampo == "ICM"
       cSD1Detalhe := 'SD1DETAILE'
       //Cabeçalho
       cCpoGetBC := "F1_BICMS"
       cCpoGetVC := "F1_VICMS"

       cCpoLoadBC := "F1_BASEICM"
       cCpoLoadVC := "F1_VALICM"

       //Itens
       cCpoGetB := "D1_BICMS"
       cCpoGetP := "D1_PICMS"
       cCpoGetV := "D1_VICMS"

       cCpoLoadB := "D1_BASEICM"
       cCpoLoadP := "D1_PICM"
       cCpoLoadV := "D1_VALICM"
    EndIf

    _oModelDET := _oModel:GetModel(cSD1Detalhe)

    _nImp := _oModel:GetValue( cSD1Detalhe , cCpoGetV )

    _oModel:LoadValue( cSD1Detalhe,cCpoLoadV,_nImp)

    _nQtdLin	:= _oModelDET:Length()
    _nLinPos    := _oModelDET:GetLine() 

    For i := 1 to _nQtdLin
        _oModelDET:GoLine( i )
        _nTotBase += _oModel:GetValue( cSD1Detalhe , cCpoGetB )
        _nTotVr   += _oModel:GetValue( cSD1Detalhe , cCpoLoadV )
    Next

    _oModel:LoadValue( 'SF1CAB',cCpoGetBC,_nTotBase )
    _oModel:LoadValue( 'SF1CAB',cCpoGetVC,_nTotVr   )
    _oModel:LoadValue( 'SF1CAB',cCpoLoadBC,_nTotBase)
    _oModel:LoadValue( 'SF1CAB',cCpoLoadVC,_nTotVr  )

    _oModelDET:GoLine( _nLinPos ) 

Return _nImp

/*
===============================================================================================================================
Programa----------: MFIS010IMP
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Gatilho que calcula o Valor de Pis e Cofins
Parametros--------: cCampo: Pis ou Cofins
Retorno-----------: Vr do Imposto
===============================================================================================================================
*/
User Function MFIS010BAS() As Numeric

    Local _oModel   := FWModelActive() As Object
    Local _nRet := 0 As Numeric

    _nRet	:= _oModel:GetValue( 'SD1DETAILE' , 'D1_BASDES') 

Return _nRet

/*
===============================================================================================================================
Programa----------: MFIS010FIS
Autor-------------: Igor Melgaço
Data da Criacao---: 23/05/2023
Descrição---------: Validação para alteração de acodordo com o MV_DATAFIS
Parametros--------: _oModel
Retorno-----------: lRet
===============================================================================================================================
*/
User Function MFIS010FIS(_oModel As Object) As Logical

    Local lRet := .T. As Logical
    Local _dDtAux := GetMV( "MV_DATAFIS" , , SToD("") ) As Date
    Local _cMenPro := "Data de digitação menor/igual ao bloqueio para operações Fiscais. Solicite o desbloqueio à Contabilidade." As Character
    Local _cMenRes := "Solicite o desbloqueio à Contabilidade." As Character
    Local _nOper := _oModel:GetOperation() As Numeric

    If _nOper == MODEL_OPERATION_UPDATE .And. SF1->F1_DTDIGIT <= _dDtAux
        //help( cRotina , nLinha , cCampo , cNome , cMensagem , nLinha1 , nColuna , lPop , hWnd , nHeight , nWidth , lGravaLog , aSoluc )
        Help(NIL, NIL, "MFIS010FIS", NIL, _cMenPro,1, 0, NIL, NIL, NIL, NIL, NIL, {_cMenRes})
        lRet := .F.
    EndIf

Return lRet

/*
===============================================================================================================================
Programa----------: MFIS010LOG
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Rotina para Verificar alterações dos campos e guradar informação de Log
Parametros--------: 
Retorno-----------: lRet
===============================================================================================================================
*/
User Function MFIS010LOG() As Logical

    Local _oModel      := FWModelActive() As Object
    Local _oModelDETF  := _oModel:GetModel('SD1DETAILF') As Object
    Local _oModelDETE  := _oModel:GetModel('SD1DETAILE') As Object
    Local _aCpSF1      := {"F1_BASIMP6","F1_BASIMP5","F1_VALIMP6","F1_VALIMP5"} As Array
    Local _aCpSD1P     := {"D1_BASIMP6","D1_BASIMP5","D1_VALIMP6","D1_VALIMP5","D1_ALQIMP6","D1_ALQIMP5"} As Array
    Local _aCpSD1I     := {"D1_ITEM","D1_CF","D1_TES","D1_DIFAL","D1_BASEDES","D1_ICMSCOM","D1_BASNDES","D1_ALQNDES","D1_ICMNDES"} As Array
    Local _nQtdLin     := 0 As Numeric
    Local _aCamposSD1  := {} As Array
    Local i            := 0 As Numeric
    Local j            := 0 As Numeric
    Local k            := 0 As Numeric
    Local lRet         := .T. As Logical

    _aSF1 := {}
    _aSD1P := {}
    _aSD1I := {}

    For i := 1 To Len(_aCpSF1)
        If SF1->&(_aCpSF1[i]) <> _oModel:GetValue( 'SF1CAB',_aCpSF1[i])
            aAdd(_aSF1,{_aCpSF1[i],SF1->&(_aCpSF1[i]) ,_oModel:GetValue( 'SF1CAB',_aCpSF1[i])})
        EndIf
    Next

    _nQtdLin	:= _oModelDETF:Length()

    For i := 1 to _nQtdLin

        _oModelDETF:GoLine( i )
        _oModelDETE:GoLine( i )

        _cD1_ITEM    := _oModel:GetValue( 'SD1DETAILF','D1_ITEM')
        _cChave      := _oModel:GetValue( 'SF1CAB','F1_FILIAL')+_oModel:GetValue( 'SF1CAB','F1_DOC')+_oModel:GetValue( 'SF1CAB','F1_SERIE')+_oModel:GetValue( 'SF1CAB','F1_FORNECE')+_oModel:GetValue( 'SF1CAB','F1_LOJA')
        
        DBSelectArea("SD1")
        DBSetOrder(1)
        If DBSeek(_cChave)
            _aCamposSD1 := {}
            For j := 1 To Len(_aCpSD1P)
                If SD1->&(_aCpSD1P[j]) <> _oModel:GetValue( 'SD1DETAILF',_aCpSD1P[j])
                    aAdd(_aCamposSD1,{_aCpSD1P[j],SD1->&(_aCpSD1P[j]) ,_oModel:GetValue( 'SD1DETAILF',_aCpSD1P[j])})
                EndIf
            Next
            aAdd(_aSD1P,{_cChave+_cD1_ITEM,_aCamposSD1})

            _aCamposSD1 := {}
            For k := 1 To Len(_aCpSD1I)
                If SD1->&(_aCpSD1I[k]) <> _oModel:GetValue( 'SD1DETAILE',_aCpSD1I[k])
                    aAdd(_aCamposSD1,{_aCpSD1I[k],SD1->&(_aCpSD1I[k]) ,_oModel:GetValue( 'SD1DETAILE',_aCpSD1I[k])})
                EndIf
            Next
            aAdd(_aSD1I,{_cChave+_cD1_ITEM,_aCamposSD1})
        EndIf

    Next

Return lRet

/*
===============================================================================================================================
Programa----------: MFIS010CON
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Consulta Histórico de Alterações 
Parametros--------: _cChave
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS010CON(_cTipo As Character) As Void

    Local _oModel      := FWModelActive() As Object
    Local _aCabec      := {} As Array
    Local _cTabela     := "" As Character
    Local _cChave      := "" As Character
    Local _cCpoChave   := "" As Character
    Local _cTitulo     := "" As Character

    If _cTipo == "CAB"
        _cTabela   := "SF1"
        _cChave    := SF1->F1_FILIAL + SF1->F1_DOC + SF1->F1_SERIE + SF1->F1_FORNECE + SF1->F1_LOJA
        _cCpoChave := "SF1.F1_FILIAL || SF1.F1_DOC || SF1.F1_SERIE || SF1.F1_FORNECE || SF1.F1_LOJA "
        _cTitulo   := "Log de Alterações da Nota de Entrada"

        aAdd( _aCabec, {"Nota Fiscal / Serie",SF1->F1_DOC + " / " + SF1->F1_SERIE} )
        aAdd( _aCabec, {"Fornecedor:",SF1->F1_FORNECE + " - " + SF1->F1_LOJA + " " + Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_NOME")} )
    Else
        _cTabela   := "SD1"
        _cChave    := _oModel:GetValue( 'SF1CAB','F1_FILIAL')+_oModel:GetValue( 'SF1CAB','F1_DOC')+_oModel:GetValue( 'SF1CAB','F1_SERIE')+_oModel:GetValue( 'SF1CAB','F1_FORNECE')+_oModel:GetValue( 'SF1CAB','F1_LOJA')+_oModel:GetValue( 'SD1DETAILF','D1_ITEM')
        _cCpoChave := "SD1.D1_FILIAL || SD1.D1_DOC || SD1.D1_SERIE || SD1.D1_FORNECE || SD1.D1_LOJA || SD1.D1_ITEM"
        _cTitulo   := "Log de Alterações do item da Nota de Entrada"

        aAdd( _aCabec, {"Nota Fiscal / Serie",SF1->F1_DOC + " / " + SF1->F1_SERIE} )
        aAdd( _aCabec, {"Fornecedor:",SF1->F1_FORNECE + " - " + SF1->F1_LOJA + " " + Posicione("SA2",1,xFilial("SA2")+SF1->F1_FORNECE+SF1->F1_LOJA,"A2_NOME")} )
    EndIf

    U_MFIS009T(_aCabec,_cTabela,_cChave,_cCpoChave,_cTitulo)

Return 

/*
===============================================================================================================================
Programa----------: MFIS010WHE
Autor-------------: Igor Melgaço
Data da Criacao---: 19/05/2023
Descrição---------: Gatilho de Campos 
Parametros--------: _cCampo
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MFIS010WHE(_cCampo As Character) As Logical

    Local _oModel    := FWModelActive() As Object

    If _cCampo == "D1_TRIBUT"
        _oModel:LoadValue( 'SD1DETAILE','D1_TES' ,_oModel:GetValue( 'SD1DETAILE','D1_TRIBUT'))
    ElseIf _cCampo == "D1_CLASSEF"
        _oModel:LoadValue( 'SD1DETAILE','D1_CLASFIS' ,_oModel:GetValue( 'SD1DETAILE','D1_CLASSEF'))
    ElseIf _cCampo == "D1_CODFISC"
        _oModel:LoadValue( 'SD1DETAILE','D1_CF' ,_oModel:GetValue( 'SD1DETAILE','D1_CODFISC'))
    EndIf

Return .T.
