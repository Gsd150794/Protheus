/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer     | 09/10/2017 | Correção do erro de não existir acols - Chamado 21805
------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer     | 11/03/2019 | Não validar o preenchimento das filais quando o codigo da operação For = "22". Chamado 28396
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "FWMVCDEF.CH"
#Include "TOPCONN.CH"

/*
===============================================================================================================================
Programa----------: AOMS001
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Fazer manutenção na tabela de preços de transferencias de notas fiscais
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/

User Function AOMS001()
Local oBrowse
Local aArea := Z09->(GetArea())

U_ITLOGACS()//Grava log de utilização da rotina

oBrowse := FWMBrowse():New()
oBrowse:SetAlias( 'Z09' )
oBrowse:SetFilterDefault( 'U_AOMS001C()' )
oBrowse:SetDescription( 'Tabela preço de transferencias' )
oBrowse:SetOnlyFields( { 'Z09_FILORI','Z09_FILDES','Z09_CODOPE' , 'Z09_DESOPE' , 'Z09_INIVIG' , 'Z09_FIMVIG' , 'Z09_DESVIO' } )
oBrowse:DisableDetails()

oBrowse:Activate()

FWRestArea(aArea)

Return .T.


/*
===============================================================================================================================
Programa----------: MENUDEF
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: menu de opções
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Vetor de opções
===============================================================================================================================
*/

Static Function MenuDef()
Local aRotina := {}

ADD OPTION aRotina TITLE 'Visualizar' ACTION 'VIEWDEF.AOMS001' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Incluir'    ACTION 'VIEWDEF.AOMS001' OPERATION 3 ACCESS 0
ADD OPTION aRotina TITLE 'Alterar'    ACTION 'VIEWDEF.AOMS001' OPERATION 4 ACCESS 0
ADD OPTION aRotina TITLE 'Excluir'    ACTION 'VIEWDEF.AOMS001' OPERATION 5 ACCESS 0
ADD OPTION aRotina TITLE 'Copiar'     ACTION 'VIEWDEF.AOMS001' OPERATION 9 ACCESS 0

Return aRotina

/*
===============================================================================================================================
Programa----------: MODELDEF
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Criação do modelo de dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Modelo dados
===============================================================================================================================
*/

Static Function ModelDef()
// Cria a estrutura a ser usada no Modelo de Dados
Local oStruPAI := FWFormStruct( 1, 'Z09', /*bAvalCampo*/, /*lViewUsado*/ )
Local oStruFIL := FWFormStruct( 1, 'Z09', /*bAvalCampo*/, /*lViewUsado*/ )
Local oModel


//remover campos
oStruPAI:RemoveField( 'Z09_CODPRO' )
oStruPAI:RemoveField( 'Z09_DESPRO' )
oStruPAI:RemoveField( 'Z09_PRECO'  )
oStruPAI:RemoveField( 'Z09_FILORI' )
oStruPAI:RemoveField( 'Z09_FILDES' )
oStruFIL:RemoveField( 'Z09_CODOPE' )
oStruFIL:RemoveField( 'Z09_DESOPE' )
oStruFIL:RemoveField( 'Z09_INIVIG' )
oStruFIL:RemoveField( 'Z09_FIMVIG' )
oStruFIL:RemoveField( 'Z09_DESVIO' )


// Cria o objeto do Modelo de Dados
oModel := MPFormModel():New( 'MAOMS001' , /*bPreValidacao*/ , /*bPosValidacao*/ {|oMdl| MDPosVld(oMdl)}, /*bCommit*/ {|oMdl| MDGrv(oMdl)}, /*bCancel*/ )

// Adiciona a descricao do Modelo de Dados
oModel:SetDescription( 'Tabela Preco de transferencias' )

// Adiciona ao modelo uma estrutura de formulário de edição por campo
oModel:AddFields( 'Z09PAI', NIL, oStruPAI,/*bPre-Validacao*/ ,/*bPos-Validacao*/,/*bCarga*/ )

// Adiciona ao modelo uma estrutura de formulário de edição por grid
oModel:AddGrid( 'Z09FIL', 'Z09PAI', oStruFIL , /*bLinePre*/, {|oMdl| AOMS001LV(oMdl)} , /*bPreVal*/ , /*bPosVal*/ , /*BLoad*/  )

//define a chave primaria
oModel:SetPrimaryKey( {"Z09_FILIAL", "Z09_CODOPE","Z09_INIVIG","Z09_FIMVIG"})

// Faz relaciomaneto entre os compomentes do model
_arelacao := {}

aAdd(_arelacao, { 'Z09_FILIAL', 'xFilial( "Z09" ) ' })
aAdd(_arelacao, { 'Z09_CODOPE', 'Z09_CODOPE' })
aAdd(_arelacao, { 'Z09_INIVIG', 'Z09_INIVIG' })
aAdd(_arelacao, { 'Z09_FIMVIG', 'Z09_FIMVIG' })
		
oModel:SetRelation( 'Z09FIL', _arelacao , Z09->( IndexKey( 4 ) ) )

// Liga o controle de nao repeticao de linha
oModel:GetModel( 'Z09FIL' ):SetUniqueLine( { 'Z09_CODPRO','Z09_FILORI','Z09_FILDES' } )

// Adiciona a descricao do Componente do Modelo de Dados
oModel:GetModel( 'Z09PAI' ):SetDescription( 'Dados da Operacao' )
oModel:GetModel( 'Z09FIL' ):SetDescription( 'Dados do Produto'  )

//define obrigatoriedade de linha digiada no grid
oModel:GetModel( 'Z09FIL' ):SetOptional( .F. )

//validacao da ativacao do modelo
oModel:SetVldActivate( { |oModel| AtivaModelo( oModel ) } )

Return oModel

/*
===============================================================================================================================
Programa----------: VIEWDEF
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Criação da visão dos dados
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Visão dos dados
===============================================================================================================================
*/
Static Function ViewDef()
// Cria a estrutura a ser usada na View
Local oStruPAI := FWFormStruct( 2, 'Z09' )
Local oStruFIL := FWFormStruct( 2, 'Z09' )

// Cria um objeto de Modelo de Dados baseado no ModelDef do fonte informado
Local oModel   := FWLoadModel( 'AOMS001' )
Local oView

// remover campos
oStruPAI:RemoveField( 'Z09_CODPRO' )
oStruPAI:RemoveField( 'Z09_DESPRO' )
oStruPAI:RemoveField( 'Z09_PRECO'  )
oStruPAI:RemoveField( 'Z09_FILORI' )
oStruPAI:RemoveField( 'Z09_FILDES' )
oStruFIL:RemoveField( 'Z09_CODOPE' )
oStruFIL:RemoveField( 'Z09_DESOPE' )
oStruFIL:RemoveField( 'Z09_INIVIG' )
oStruFIL:RemoveField( 'Z09_FIMVIG' )
oStruFIL:RemoveField( 'Z09_DESVIO' )

// Cria o objeto de View
oView := FWFormView():New()

// Define qual o Modelo de dados será utilizado
oView:SetModel( oModel )

//Adiciona no nosso View um controle do tipo FormFields(antiga enchoice)
oView:AddField( 'VIEW_PAI' , oStruPAI, 'Z09PAI'  )

//Adiciona no nosso View um controle do tipo FormGrid(antiga newgetdados)
oView:AddGrid(  'VIEW_FIL' , oStruFIL, 'Z09FIL'  )

// Criar "box" horizontal para receber algum elemento da view
oView:CreateHorizontalBox( 'BOXPAI'  , 24)
oView:CreateHorizontalBox( 'BOXFIL'  , 76)

// Relaciona o ID da View com o "box" para exibicao
oView:SetOwnerView( 'VIEW_PAI' , 'BOXPAI'  )
oView:SetOwnerView( 'VIEW_FIL' , 'BOXFIL'  )

// Liga apresentação dos titulso dos componentes
oView:EnableTitleView( 'VIEW_PAI' )
oView:EnableTitleView( 'VIEW_FIL' )

//botao adicional
oView:AddUserButton( 'Importar Produtos', 'CLIPS', {|oView| ImportGrid(oView)},,,{MODEL_OPERATION_INSERT,MODEL_OPERATION_UPDATE} )
oView:AddUserButton( 'Pesquisar Produtos', 'CLIPS', {|oView| PesqProd(oView)} )

//fechamento da view
oView:SetCloseOnOk({|oModel| If(oModel:GetOperation()=MODEL_OPERATION_UPDATE,.T.,.F.)})

Return oView

/*
===============================================================================================================================
Programa----------: MDGRV
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Complemento de gravação da modelo de dados
===============================================================================================================================
Parametros--------: objeto da modelo de dados
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MDGrv(oMdl)

Local oModelCab  := oMdl:GetModel( 'Z09PAI' )
Local nOperacao  := oMdl:GetOperation()
Local cOper      := oModelCab:GetValue("Z09_CODOPE")
Local aArea      := FWGetArea()

FwFormCommit(oMdl)

//alteracao
If nOperacao=MODEL_OPERATION_UPDATE
	
	DBSelectArea("Z09")
	Z09->( DBSetOrder(2) )
	Z09->(DBSeek(xFilial("Z09")+oModelCAB:GetValue("Z09_CODOPE")))
	
	While Z09->(!Eof()) .And. Z09->Z09_CODOPE == cOper
		
		RecLock("Z09",.F.)
		Z09->Z09_DESVIO := oModelCAB:GetValue("Z09_DESVIO")
		Z09->Z09_INIVIG := oModelCAB:GetValue("Z09_INIVIG")
		Z09->Z09_FIMVIG := oModelCAB:GetValue("Z09_FIMVIG")
		Z09->(MSUnLock())
		
		Z09->(DBSkip())
		
	EndDo
	
EndIf

FWRestArea(aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: ImportGrid
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Importação dos dados para a modelo
===============================================================================================================================
Parametros--------: Objeto da visão de dados
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function ImportGrid(oView)

Local oModel := FWModelActive()
Local oModelGrid := oModel:GetModel( 'Z09FIL' )
Local cAliasQry := GetNextAlias()
Local cTipo := 'PA'

//consultar banco de produtos
BeginSql Alias cAliasQry
	SELECT B1_COD, B1_DESC
	FROM %Table:SB1%
	WHERE %NotDel%
	AND B1_FILIAL = %xFilial:SB1%
	AND	B1_TIPO = %Exp:cTipo%
	AND B1_MSBLQL <> '1'
	ORDER BY B1_COD
EndSql

(cAliasQry)->(DBGoTop())

//preenchimento do grid
While (cAliasQry)->(!Eof())
	
	If !oModelGrid:Seekline({ {"Z09_CODPRO",(cAliasQry)->B1_COD} },.F.)
		oModelGrid:AddLine()
		oModelGrid:SetValue( "Z09_CODPRO",(cAliasQry)->B1_COD )
	EndIf
	(cAliasQry)->(DBSkip())
EndDo

(cAliasQry)->(DBCloseArea())

oModelGrid:GoLine(1)

Return .T.

/*
===============================================================================================================================
Programa----------: PesqProd
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Pesquisar produto na modelo de dados
===============================================================================================================================
Parametros--------: Objeto da visão de dados
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function PesqProd(oView)

Local oModel := FWModelActive()
Local oModelGrid := oModel:GetModel( 'Z09FIL' )
Local oDlg , oButton1 , oGet1 , oSay1
Local cProd := Space(15)

DEFINE MSDIALOG oDlg TITLE "Pesquisar produto" FROM 000, 000  TO 100, 400 COLORS 0, 16777215 PIXEL
@ 017, 014 Say oSay1 PROMPT "Codigo Produto:" SIZE 041, 007 OF oDlg COLORS 0, 16777215 PIXEL
@ 015, 055 MSGET oGet1 VAR cProd SIZE 097, 010 OF oDlg PICTURE "@!" COLORS 0, 16777215 F3 "Z09B1" PIXEL
DEFINE SBUTTON oButton1 FROM 030, 115 Type 01 OF oDlg ENABLE ACTION {|| oDlg:End()}
ACTIVATE MSDIALOG oDlg

//posicionar no grid
oModelGrid:Seekline({ {"Z09_CODPRO",cProd} },.F.)

Return .T.

/*
===============================================================================================================================
Programa----------: AtivaModelo
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Validar ativação do modelo
===============================================================================================================================
Parametros--------: Objeto da modelo de dados
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
Static Function AtivaModelo(oModel)

Local aArea		:= FWGetArea()
Local lRet      := .T.

If !U_ITVLDUSR(8)
	U_ITMsg('O usuário '+UsrRetName( RetCodUsr() )+' não possui acesso para manutenção dos preços de transferências.',,'Informar ao suporte T.I. para realizar essa manutenção.',,,,.T.)
	lRet := .F.
EndIf

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: MDPosVld
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Validação da modelo de dados
===============================================================================================================================
Parametros--------: Objeto do modelo de dados
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
===============================================================================================================================
*/
Static Function MDPosVld(oMdl)

Local oModelGrid := oMdl:GetModel( 'Z09FIL' )
Local lRet := .T.
Local nx := 0
Local aArea	:= FWGetArea()

//validar preço
For nx := 1 To oModelGrid:Length()
	oModelGrid:GoLine(nx)
	If !oModelGrid:IsDeleted()
		If oModelGrid:GetValue('Z09_PRECO',nx) <= 0
			lRet := .F.
			U_ITMsg('Produto '+AllTrim(oModelGrid:GetValue("Z09_CODPRO",nx))+' com preço zerado.',,'Acerte o preço do produto para um valor maior que zero',,,,.T.)
		EndIf
	EndIf
Next nx

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: AOMS001A
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Validação do periodo de vigencia executada na validação do dicionario
===============================================================================================================================
Parametros--------: dIniData = Data inicio da vigencia
					dFimData = Data fim da vigencia
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function AOMS001A(dIniData,dFimData)

Local _lRet := .T.


If dFimData <= dIniData .And. !Empty(dFimData)

	_lRet := .F.
	U_ITMsg("Data final da vigência deve ser maior que a data inicio da vigência.",,,,,,.T.)

EndIf

Return _lRet 

/*
===============================================================================================================================
Programa----------: AOMS001H
Autor-------------: Josué Danich
Data da Criacao---: 15/09/2015
===============================================================================================================================
Descrição---------: Validação do código de operação
===============================================================================================================================
Parametros--------: _cCodop = Código da operação
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function AOMS001H(_cCodop)

Local lRet := .T.
Local aArea	:= FWGetArea()
Local cQuery	:= ''
Local cAlias	:= GetNextAlias()

If (Inclui .Or. Altera) 

	//valida operação  não pode sobrepor com nenhum registro já existente
	cQuery += " SELECT Z09.Z09_CODOPE FROM "+ RETSQLNAME('Z09') +" Z09 WHERE "+ RETSQLCOND('Z09') 
	cQuery += " AND Z09.Z09_CODOPE = '"+ _cCodop +"'"

	IIf( Select(cAlias) > 0 , (cAlias)->( DBCloseArea() ) , Nil )

	DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , cAlias , .F. , .T. )
	DBSelectArea(cAlias)

	//se achou mesma operação  alerta e bloqueia o cadastro
	If .not. (cAlias)->( Eof() )
  	    U_ITMsg("Operação conflitante com registro já existente",,,,,,.T.)
		lRet := .F.
	
	EndIf

EndIf

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: AOMS001C
Autor-------------: Xavier
Data da Criacao---: 30-03-2015
===============================================================================================================================
Descrição---------: Filtrar dados na tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
User Function AOMS001C()

Local aArea	:= FWGetArea()
Local cQuery	:= ''
Local cAlias	:= GetNextAlias()
Local lRet		:= .F.

cQuery += " SELECT Z09.R_E_C_N_O_ AS REGZ09 FROM "+ RETSQLNAME('Z09') +" Z09 WHERE "+ RETSQLCOND('Z09') 
cQuery += " AND Z09.Z09_CODOPE = '"+ Z09->Z09_CODOPE +"' AND Z09.Z09_INIVIG = '" + DToS(Z09->Z09_INIVIG) + "'" 
cQuery += " AND Z09.Z09_FIMVIG = '" + DToS(Z09->Z09_FIMVIG) + "' AND ROWNUM = 1 ORDER BY 1 "


IIf( Select(cAlias) > 0 , (cAlias)->( DBCloseArea() ) , Nil )

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, cQuery ) , cAlias , .F. , .T. )
DBSelectArea(cAlias)
(cAlias)->( DBGoTop() )

lRet := ( (cAlias)->REGZ09 == Z09->( Recno() ) )

(cAlias)->( DBCloseArea() )

FWRestArea(aArea)

Return lRet

/*
===============================================================================================================================
Programa----------: AOMS001LV
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/09/2015
===============================================================================================================================
Descrição---------: Validar linha do grid
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Logico
===============================================================================================================================
*/
Static Function AOMS001LV(oMdl)

Local _lRet := .T.
Local _oModel	:= FWModelActive()
Local oModelGrid:= _oModel:GetModel( 'Z09FIL' )
Local _cFilori := oModelGrid:GetValue("Z09_FILORI")//AllTrim(aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "Z09_FILORI"})])
Local _cFildes := oModelGrid:GetValue("Z09_FILDES")//AllTrim(aCols[n][aScan(aHeader,{|x| Upper(AllTrim(x[2])) == "Z09_FILDES"})])

If Z09->Z09_CODOPE <> "22"
	If  .NOT.( Empty(_cFilori) .And.  Empty(_cFildes)).AND. ;
	    .NOT.(!Empty(_cFilori) .And. !Empty(_cFildes) .And. AllTrim(_cFilori) <> AllTrim(_cFildes) ) 

       U_ITMsg("Campos de filial origem / destino devem ser diferentes ou vazios.",," Acertar Linha: "+AllTrim(Str(oModelGrid:NLINE)),,,,.T.)
	   _lRet := .F.
	
	EndIf

ElseIf  Z09->Z09_CODOPE = "22"
	If Empty(_cFilori) .Or. Empty(_cFildes) .Or. AllTrim(_cFilori) <> AllTrim(_cFildes)

       U_ITMsg("Campos de filial origem / destino devem ser preenchidos e iguais.",," Acertar Linha: "+AllTrim(Str(oModelGrid:NLINE)),,,,.T.)
	   _lRet := .F.
	
	EndIf
EndIf	
    

Return _lRet
