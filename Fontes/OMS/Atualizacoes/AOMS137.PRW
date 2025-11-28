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
Programa--------: AOMS137
Autor-----------: Igor Melgaço
Data da Criacao-: 05/04/2023
===============================================================================================================================
Descrição-------: Cadastro de transit time - Chamado 43483
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/

User Function AOMS137()

Local _aArea   := FWGetArea()
Local _oBrowse

    _oBrowse := FWMBrowse():New()
    _oBrowse:SetAlias("Z31")
    _oBrowse:SetMenuDef( 'AOMS137' )
    _oBrowse:SetDescription("Transit time por Operador Logistico")
    _oBrowse:Activate()

    FWRestArea(_aArea)
    
Return

/*
===============================================================================================================================
Programa--------: AOMS137 - MenuDef
Autor-----------: Igor Melgaço
Data da Criacao-: 05/04/2023
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
ADD OPTION _aRot TITLE 'Visualizar' ACTION 'VIEWDEF.AOMS137' 	OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
ADD OPTION _aRot TITLE 'Incluir'    ACTION 'VIEWDEF.AOMS137' 	OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
ADD OPTION _aRot TITLE 'Alterar'    ACTION 'VIEWDEF.AOMS137' 	OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
ADD OPTION _aRot TITLE 'Excluir'    ACTION 'VIEWDEF.AOMS137' 	OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return _aRot
*/
Return( FWMVCMenu("AOMS137") )
/*
===============================================================================================================================
Programa--------: AOMS137 - ModelDef 
Autor-----------: Igor Melgaço
Data da Criacao-: 05/04/2023
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
Local _bValid	:= {|_oModel| U_AOMS137V(_oModel)}

//Criação da estrutura de dados utilizada na interface
Local _oStZ31CAB := FWFormStruct(1,"Z31",{ |x| AllTrim(x) $ 'Z31_FORNEC, Z31_LOJA, Z31_NOMEFO, Z31_UF' } )
Local _oStZ31DET := FWFormStruct(1,"Z31",{ |x| AllTrim(x) $ 'Z31_MESO,Z31_NMESO, Z31_MICRO, Z31_NMICRO, Z31_CODMUN, Z31_MUN, Z31_TTIME' } )

Local _aGatAux	:= {}

//Z31_FORNEC  
_aGatAux := FwStruTrigger( 'Z31_FORNEC', 'Z31_LOJA', 'IIf(Empty(AllTrim(M->Z31_LOJA)),Posicione("SA2",1,xFilial("SA2")+M->Z31_FORNEC,"A2_LOJA"),M->Z31_LOJA)', .F. )
_oStZ31CAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_FORNEC', 'Z31_NOMEFO', 'Posicione("SA2",1,xFilial("SA2")+M->Z31_FORNEC+M->Z31_LOJA,"A2_NOME")', .F. )
_oStZ31CAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_FORNEC', 'Z31_UF', 'Posicione("SA2",1,xFilial("SA2")+M->Z31_FORNEC+M->Z31_LOJA,"A2_EST")', .F. )
_oStZ31CAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Z31_LOJA
_aGatAux := FwStruTrigger( 'Z31_LOJA', 'Z31_NOMEFO', 'Posicione("SA2",1,xFilial("SA2")+M->Z31_FORNEC+M->Z31_LOJA,"A2_NOME")', .F. )
_oStZ31CAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_LOJA', 'Z31_UF', 'Posicione("SA2",1,xFilial("SA2")+M->Z31_FORNEC+M->Z31_LOJA,"A2_EST")', .F. )
_oStZ31CAB:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Z31_MESO
_aGatAux := FwStruTrigger( 'Z31_MESO', 'Z31_NMESO', 'Posicione("Z21",1,xFilial("Z21")+M->Z31_MESO,"Z21_NOME")', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MESO', 'Z31_MICRO', 'Space(Len(Z31->Z31_MICRO))', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MESO', 'Z31_NMICRO', '""', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MESO', 'Z31_CODMUN', 'Space(Len(Z31->Z31_CODMUN))', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MESO', 'Z31_MUN', '""', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Z31_MICRO
_aGatAux := FwStruTrigger( 'Z31_MICRO', 'Z31_NMICRO', 'Posicione("Z22",1,xFilial("Z22")+M->Z31_MICRO,"Z22_NOME")', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MICRO', 'Z31_CODMUN', 'Space(Len(Z31->Z31_CODMUN))', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

_aGatAux := FwStruTrigger( 'Z31_MICRO', 'Z31_MUN', '""', .F. )
_oStZ31DET:AddTrigger( _aGatAux[01] , _aGatAux[02] , _aGatAux[03] , _aGatAux[04] )

//Instanciando o modelo, não é recomendado colocar nome da User Function (por causa do u_), respeitando 10 caracteres
_oModel := MPFormModel():New("AOMS137M",,_bValid ,/*bCommit*/,/*bCancel*/) 
    
//Atribuindo formulários para o modelo
_oModel:AddFields("Z31MASTER",/*cOwner*/,_oStZ31CAB)
_oModel:AddGrid("Z31DETAIL" , "Z31MASTER" , _oStZ31DET , )
_oModel:SetRelation( "Z31DETAIL" , {	{ 'Z31_FILIAL'	, 'xFilial("Z31")'	} ,;
                                        { 'Z31_FORNEC'	, 'Z31_FORNEC'	    } ,;
										{ 'Z31_LOJA'	, 'Z31_LOJA'	    } }, Z31->( IndexKey( 1 ) ) )

_oModel:GetModel( 'Z31DETAIL' ):SetUniqueLine( { 'Z31_MESO','Z31_MICRO','Z31_CODMUN' } )   

//Setando a chave primária da rotina
_oModel:SetPrimaryKey({'Z31_FILIAL','Z31->Z31_FORNEC','Z31->Z31_LOJA','Z31->Z31_UF'})
     
//Adicionando descrição ao modelo
_oModel:SetDescription("Transit Time por Operador Logistico")

//Setando a descrição do formulário
//_oModel:GetModel( "Z31MASTER" ):SetDescription( "Transit Time por Operador Logistico"		)
//_oModel:GetModel( "Z31DETAIL" ):SetDescription( ""	)

// Define validação inical do modelo
_oModel:SetVldActivate( { |_oModel| AOMS137VLD( _oModel ) } )

Return _oModel

Static Function AOMS137VLD(_oModel)

Return .T.

/*
===============================================================================================================================
Programa--------: AOMS137 - ViewDef 
Autor-----------: Igor Melgaço
Data da Criacao-: 05/04/2023
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
Local _oModel := FWLoadModel("AOMS137")

//Criação da estrutura de dados utilizada na interface do cadastro de Autor
Local _oStZ31CAB := FWFormStruct(2,"Z31",{ |x| AllTrim(x) $ 'Z31_FORNEC, Z31_LOJA, Z31_NOMEFO,Z31_UF' } )
Local _oStZ31DET := FWFormStruct(2,"Z31",{ |x| AllTrim(x) $ 'Z31_MESO,Z31_NMESO, Z31_MICRO, Z31_NMICRO, Z31_CODMUN, Z31_MUN, Z31_TTIME' } )
          
//Criando _oView como nulo
Local _oView := Nil
 
//Criando a view que será o retorno da função e setando o modelo da rotina
_oView := FWFormView():New()
_oView:SetModel(_oModel)
     
//Atribuindo formulários para interface
_oView:AddField( "VIEW_MASTER", _oStZ31CAB	, "Z31MASTER" )
_oView:AddGrid(  "VIEW_DETAIL", _oStZ31DET	, "Z31DETAIL" )
     
//Criando um container com nome tela com 100%
_oView:CreateHorizontalBox( 'BOX0101' , 20 )
_oView:CreateHorizontalBox( 'BOX0102' , 80 )
_oView:SetOwnerView( "VIEW_MASTER" , "BOX0101" )
_oView:SetOwnerView( "VIEW_DETAIL" , "BOX0102" )

//Colocando título do formulário
//_oView:EnableTitleView('VIEW_Z31', 'Cadastro de Transit Time por Operador Logistico' )  
     
//Força o fechamento da janela na confirmação
_oView:SetCloseOnOk({||.T.})
     
//O formulário da interface será colocado dentro do container
//_oView:SetOwnerView("VIEW_Z31","TELA")

Return _oView

/*
===============================================================================================================================
Programa--------: AOMS137V
Autor-----------: Igor Melgaço
Data da Criacao-: 05/04/2023
===============================================================================================================================
Descrição-------: Validação pré gravação
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _lOk - lógico permitindo ou não a gravação
===============================================================================================================================
*/  
User Function AOMS137V(_oModel)

Local _lOk        := .T.
Local _nOperation := _oModel:GetOperation() 
Local _cFornec    := _oModel:GetValue( 'Z31MASTER', 'Z31_FORNEC' )
Local _cLoja      := _oModel:GetValue( 'Z31MASTER', 'Z31_LOJA' )
Local _cUF        := _oModel:GetValue( 'Z31MASTER', 'Z31_UF' )
Local _lValida    := .F.
Local _aOrd       := SaveOrd({"Z31"})

If _nOperation == MODEL_OPERATION_INSERT 
    _lValida      := .T.
EndIf

If _lValida
    Z31->(DBSetOrder(1))
	If Z31->( DBSeek(xFilial("Z31") + _cFornec + _cLoja + _cUF ) )

		_lOk := .F.
		U_ITMsg("Chave (fornecedor + Loja + Estado) informada já consta no cadastro. ",;
                "Atenção",;
                "Verifique e modifique o chave digitada.  ",3 , , , .T.)	
	EndIf
EndIf

RestOrd(_aOrd)

Return _lOk

/*
===============================================================================================================================
Programa--------: AOMS137FIL
Autor-----------: Igor Melgaço
Data da Criacao-: 11/04/2023
===============================================================================================================================
Descrição-------: Filtro para consultas padrão
===============================================================================================================================
Parametros------: cTabela - Tabela onde será efetuada o filtro
===============================================================================================================================
Retorno---------: _cRetorno - Chave para filtro na consulta padrão
===============================================================================================================================
*/  
User Function AOMS137FIL(cTabela)
Local _oModel     := FwModelActivete()
Local _cRetorno   := ""
Local _cUF        := ""
Local _cMeso      := ""
Local _cMicro     := ""

    _cUF    := _oModel:GetValue( 'Z31MASTER', 'Z31_UF' )
    _cMeso  := _oModel:GetValue( 'Z31DETAIL', 'Z31_MESO' )
    _cMicro := _oModel:GetValue( 'Z31DETAIL', 'Z31_MICRO' )

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
Programa--------: AOMS137X
Autor-----------: Igor Melgaço
Data da Criacao-: 11/04/2023
===============================================================================================================================
Descrição-------: Preenche a Meso e Micro contidos na CC2, usado no Valid do Z31_CODMUN
===============================================================================================================================
Parametros------: 
===============================================================================================================================
Retorno---------: .T.
===============================================================================================================================
*/  
User Function AOMS137X()
Local _oModel  := FwModelActivete()
Local _cUF     := _oModel:GetValue( 'Z31MASTER', 'Z31_UF' )
Local _cCodMun := _oModel:GetValue( 'Z31DETAIL', 'Z31_CODMUN' )
Local _cMun    := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_MUN")
Local _cMeso   := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_I_MESO")
Local _cNMeso  := Posicione("Z21",1,xFilial("Z21")+_cMeso,"Z21_NOME")
Local _cMicro  := Posicione("CC2",1,xFilial("CC2")+_cUF+_cCodMun,"CC2_I_MICR")
Local _cNMicro := Posicione("Z22",1,xFilial("Z22")+_cMicro,"Z22_NOME")

_oModel:LoadValue( 'Z31DETAIL', 'Z31_MUN'   , _cMun )
_oModel:LoadValue( 'Z31DETAIL', 'Z31_MESO'  , _cMeso )
_oModel:LoadValue( 'Z31DETAIL', 'Z31_NMESO' , _cNMeso )
_oModel:LoadValue( 'Z31DETAIL', 'Z31_MICRO' , _cMicro )
_oModel:LoadValue( 'Z31DETAIL', 'Z31_NMICRO', _cNMicro )

Return .T.
