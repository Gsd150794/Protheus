/*
===============================================================================================================================
                                    ATUALIZACOES SOFRIDAS DESDE A CONSTRUÇAO INICIAL
===============================================================================================================================
 Autor        |    Data    |                              Motivo                      										 
-------------------------------------------------------------------------------------------------------------------------------

===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================


#Include "TOTVS.ch"
#Include "FwMVCDef.ch"
#Include "RWMAKE.CH"
#Include "TopConn.ch"
#Include "FWMBROWSE.CH"

/*
===============================================================================================================================
Programa--------: AOMS142
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: Cadastro de Rateio de fretes (Troca nota) - Chamado 46029 
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS142()

Local _aArea   := FWGetArea()
Local _oBrowse

    _oBrowse := FWMBrowse():New()
    _oBrowse:SetAlias("ZRF")
    _oBrowse:SetMenuDef( 'AOMS142' )
    _oBrowse:SetDescription("Rateio de fretes (Troca nota)")
    _oBrowse:Activate()

    FWRestArea(_aArea)
    
Return

/*
===============================================================================================================================
Programa--------: AOMS142 - MenuDef
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: MenuDef do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
Static Function MenuDef()
/* 
Private _aRot := {}
     
//Adicionando opções
ADD OPTION _aRot TITLE 'Visualizar' ACTION 'VIEWDEF.AOMS142' 	OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
ADD OPTION _aRot TITLE 'Incluir'    ACTION 'VIEWDEF.AOMS142' 	OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
ADD OPTION _aRot TITLE 'Alterar'    ACTION 'VIEWDEF.AOMS142' 	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
ADD OPTION _aRot TITLE 'Excluir'    ACTION 'VIEWDEF.AOMS142' 	OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return _aRot
*/
Return( FWMVCMenu("AOMS142") )
/*
===============================================================================================================================
Programa--------: AOMS142 - ModelDef 
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: ModelDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/ 
Static Function ModelDef()

//Criação do objeto do modelo de dados
Local _oModel := Nil
Local _bValid	:= {|_oModel| U_AOMS142V(_oModel)}

//Criação da estrutura de dados utilizada na interface
Local _oStZRFCAB := FWFormStruct(1,"ZRF",{ |x| AllTrim(x) $ 'ZRF_UFCAR, ZRF_MUNCAR, ZRF_NMUNCA' } )
Local _oStZRFDET := FWFormStruct(1,"ZRF",{ |x| AllTrim(x) $ 'ZRF_UFDEST, ZRF_MESODE, ZRF_NMESOD, ZRF_MICRDE, ZRF_NMICRD, ZRF_MUNDES, ZRF_NMUNDE, ZRF_PERC1T' } )

Local _aGatAux	:= {}

//ZRF_MUNCAR
_aGatAux := FwStruTrigger( 'ZRF_MUNCAR', 'ZRF_NMUNCA', 'Posicione("CC2",1,xFilial("CC2")+M->ZRF_UFCAR+M->ZRF_MUNCAR,"CC2_MUN")', .F. )
_oStZRFCAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZRF_MESO
_aGatAux := FwStruTrigger( 'ZRF_MESODE', 'ZRF_NMESOD', 'Posicione("Z21",1,xFilial("Z21")+M->ZRF_MESODE,"Z21_NOME")', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MESODE', 'ZRF_MICRDE', 'Space(Len(ZRF->ZRF_MICRDE))', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MESODE', 'ZRF_NMICRD', '""', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MESODE', 'ZRF_MUNDES', 'Space(Len(ZRF->ZRF_MUNDES))', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MESODE', 'ZRF_NMUNDE', '""', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZRF_MICRO
_aGatAux := FwStruTrigger( 'ZRF_MICRDE', 'ZRF_NMICRD', 'Posicione("Z22",1,xFilial("Z22")+M->ZRF_MICRDE,"Z22_NOME")', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MICRDE', 'ZRF_MUNDES', 'Space(Len(ZRF->ZRF_MUNDES))', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'ZRF_MICRDE', 'ZRF_NMUNDE', '""', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//ZRF_MUNDES
_aGatAux := FwStruTrigger( 'ZRF_MUNDES', 'ZRF_NMUNDE', 'Posicione("CC2",1,xFilial("CC2")+M->ZRF_UFDEST+M->ZRF_MUNDES,"CC2_MUN")', .F. )
_oStZRFDET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Instanciando o modelo, não é recomendado colocar nome da User Function (por causa do u_), respeitando 10 caracteres
_oModel := MPFormModel():New("AOMS142M",,_bValid ,/*bCommit*/,/*bCancel*/) 

//Atribuindo formulários para o modelo
_oModel:AddFields("ZRFMASTER",/*cOwner*/,_oStZRFCAB)
_oModel:AddGrid("ZRFDETAIL" , "ZRFMASTER" , _oStZRFDET , )
_oModel:SetRelation( "ZRFDETAIL" , {	{ 'ZRF_FILIAL'	, 'xFilial("ZRF")'	} ,;
                                       { 'ZRF_UFCAR'	, 'ZRF_UFCAR'	      } ,;
										         { 'ZRF_MUNCAR'	, 'ZRF_MUNCAR'	      } }, ZRF->( IndexKey( 1 ) ) )

_oModel:GetModel( 'ZRFDETAIL' ):SetUniqueLine( { 'ZRF_UFDEST','ZRF_MESODE','ZRF_MICRDE','ZRF_MUNDES' } )   

//Setando a chave primária da rotina
_oModel:SetPrimaryKey({'ZRF_FILIAL','ZRF_UFCAR, ZRF_MUNCAR','ZRF_UFDEST','ZRF_MESODE','ZRF_MICRDE','ZRF_MUNDES'})

//Adicionando descrição ao modelo
_oModel:SetDescription("Rateio de fretes (Troca nota)")

//Setando a descrição do formulário
//_oModel:GetModel( "ZRFMASTER" ):SetDescription( "Transit Time por Operador Logistico"		)
//_oModel:GetModel( "ZRFDETAIL" ):SetDescription( ""	)

// Define validação inical do modelo
_oModel:SetVldActivate( { |_oModel| AOMS142VLD( _oModel ) } )

Return _oModel




Static Function AOMS142VLD(_oModel)

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS142 - ViewDef 
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: ViewDef  do MVC
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/  
Static Function ViewDef()
 
//Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
Local _oModel := FWLoadModel("AOMS142")

//Criação da estrutura de dados utilizada na interface do cadastro de Autor
Local _oStZRFCAB := FWFormStruct(2,"ZRF",{ |x| AllTrim(x) $ 'ZRF_UFCAR, ZRF_MUNCAR, ZRF_NMUNCA' } )
Local _oStZRFDET := FWFormStruct(2,"ZRF",{ |x| AllTrim(x) $ 'ZRF_UFDEST, ZRF_MESODE, ZRF_NMESOD, ZRF_MICRDE, ZRF_NMICRD, ZRF_MUNDES, ZRF_NMUNDE, ZRF_PERC1T' } )          
//Criando _oView como nulo
Local _oView := Nil
 
//Criando a view que será o retorno da função e setando o modelo da rotina
_oView := FWFormView():New()
_oView:SetModel(_oModel)
     
//Atribuindo formulários para interface
_oView:AddField( "VIEW_MASTER", _oStZRFCAB	, "ZRFMASTER" )
_oView:AddGrid(  "VIEW_DETAIL", _oStZRFDET	, "ZRFDETAIL" )
     
//Criando um container com nome tela com 100%
_oView:CreateHorizontalBox( 'BOX0101' , 20 )
_oView:CreateHorizontalBox( 'BOX0102' , 80 )
_oView:SetOwnerView( "VIEW_MASTER" , "BOX0101" )
_oView:SetOwnerView( "VIEW_DETAIL" , "BOX0102" )

//Colocando título do formulário
//_oView:EnableTitleView('VIEW_ZRF', 'Cadastro de Transit Time por Operador Logistico' )  
     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})
     
//O formulário da interface será colocado dentro do container
//_oView:SetOwnerView("VIEW_ZRF","TELA")

Return _oView

/*
===============================================================================================================================
Programa--------: AOMS142V
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: Validação pré gravação
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _lOk - lógico permitindo ou não a gravação
===============================================================================================================================
*/  
User Function AOMS142V(_oModel)

Local _lOk        := .T.
Local _nOperation := _oModel:GetOperation() 
Local _cUFCarg    := _oModel:GetValue( 'ZRFMASTER', 'ZRF_UFCAR' )
Local _cMunCarg   := _oModel:GetValue( 'ZRFMASTER', 'ZRF_MUNCAR' )
Local _aOrd       := SaveOrd({"ZRF"})

If _nOperation == MODEL_OPERATION_INSERT 
    ZRF->(DBSetOrder(1))
	If ZRF->( DBSeek(xFilial("ZRF") + _cUFCarg + _cMunCarg ) )

		_lOk := .F.
		U_ITMsg("Chave (UF Carreg. + Municip. Carreg.) informada já consta no cadastro. ",;
                "Atenção",;
                "Verifique e modifique o chave digitada.  ",3 , , , .T.)	
	EndIf
EndIf

RestOrd(_aOrd)

Return _lOk

/*
===============================================================================================================================
Programa--------: AOMS142FIL
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: Filtro para consultas padrão
===============================================================================================================================
Parametros------: cTabela - Tabela onde será efetuada o filtro
===============================================================================================================================
Retorno---------: _cRetorno - Chave para filtro na consulta padrão
===============================================================================================================================
*/  
User Function AOMS142FIL(cTabela)
Local _oModel     := FwModelActivete()
Local _cRetorno   := ""
Local _cUF        := ""
Local _cMeso      := ""
Local _cMicro     := ""

    _cUF    := _oModel:GetValue( 'ZRFDETAIL', 'ZRF_UFDEST' )
    _cMeso  := _oModel:GetValue( 'ZRFDETAIL', 'ZRF_MESODE' )
    _cMicro := _oModel:GetValue( 'ZRFDETAIL', 'ZRF_MICRDE' )

    If cTabela == "Z21"
        _cRetorno := _cUF
    ElseIf cTabela == "Z22"
        _cRetorno := "(Z22->Z22_EST + Z22->Z22_MESO) = '"+_cUF+_cMeso+"' "
    ElseIf cTabela ==  "CC2"
        If Empty(AllTrim(_cMicro))
            If Empty(AllTrim(_cMeso))
                _cRetorno := "(CC2->CC2_EST) = '"+_cUF+"' "
            Else
                _cRetorno := "(CC2->CC2_EST + CC2->CC2_I_MESO) = '"+_cUF+_cMeso+"' "
            EndIf
        ElseIf Empty(AllTrim(_cMeso))
            _cRetorno := "(CC2->CC2_EST) = '"+_cUF+"' "
        Else
            _cRetorno := "(CC2->CC2_EST + CC2->CC2_I_MESO + CC2->CC2_I_MICR) = '"+_cUF+_cMeso+_cMicro+"' "
        EndIf
    EndIf

Return _cRetorno

/*
===============================================================================================================================
Programa--------: AOMS142X
Autor-----------: Igor Melgaço
Data da Criacao-: 11/01/2024
===============================================================================================================================
Descrição-------: Preenche a Meso e Micro contidos na CC2, usado no Valid do ZRF_CODMUN
===============================================================================================================================
Parametros------: 
===============================================================================================================================
Retorno---------: .T.
===============================================================================================================================
*/  
User Function AOMS142X()
Local _oModel  := FwModelActivete()
Local _cUF     := _oModel:GetValue( 'ZRFDETAIL', 'ZRF_UFDEST' )
Local _cCodMun := _oModel:GetValue( 'ZRFDETAIL', 'ZRF_MUNDES' )
Local _cMun    := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_MUN")
Local _cMeso   := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_I_MESO")
Local _cNMeso  := Posicione("Z21",1,xFilial("Z21")+_cMeso,"Z21_NOME")
Local _cMicro  := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_I_MICR")
Local _cNMicro := Posicione("Z22",1,xFilial("Z22")+_cMicro,"Z22_NOME")

_oModel:LoadValue( 'ZRFDETAIL', 'ZRF_MUNDES' , _cMun )
_oModel:LoadValue( 'ZRFDETAIL', 'ZRF_MESODE' , _cMeso )
_oModel:LoadValue( 'ZRFDETAIL', 'ZRF_NMESOD' , _cNMeso )
_oModel:LoadValue( 'ZRFDETAIL', 'ZRF_MICRDE' , _cMicro )
_oModel:LoadValue( 'ZRFDETAIL', 'ZRF_NMICRD' , _cNMicro )

Return .T.

/*
===============================================================================================================================
Programa----------: AOMS142PM
Autor-------------: Igor Melgaço
Data da Criacao---: 11/01/2024
===============================================================================================================================
Descrição---------: Rotina de Filtro das Consultas Padrão CC2ZRF
===============================================================================================================================
Parametros--------: _oModel := Modelo Ativo
===============================================================================================================================
Retorno-----------: _cReturn := paramwtro de Filtro da Consulta Padrão
===============================================================================================================================
*/ 
User Function AOMS142PM()
Local _aOrd    := SaveOrd({"ZRF"})
Local _oModel  := FwModelActivete()
Local _cUF     := _oModel:GetValue( 'ZRFDETAIL','ZRF_UFDEST')
Local _cMeso   := _oModel:GetValue( 'ZRFDETAIL','ZRF_MESODE')
Local _cMicro  := _oModel:GetValue( 'ZRFDETAIL','ZRF_MICRDE')
Local _lReturn := .F.

If Empty(AllTrim(_cMicro)) .And. Empty(AllTrim(_cMeso))
   _lReturn := (CC2->CC2_EST == _cUF)
ElseIf Empty(AllTrim(_cMicro)) 
   _lReturn := (CC2->CC2_EST + CC2->CC2_I_MESO == _cUF + _cMeso)
Else
   _lReturn := (CC2->CC2_EST + CC2->CC2_I_MESO + CC2->CC2_I_MICR == _cUF + _cMeso + _cMicro)
EndIf

RestOrd(_aOrd)

Return _lReturn
