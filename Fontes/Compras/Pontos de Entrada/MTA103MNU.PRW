/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |16/05/2024| Chamado 47282. Incluída chamada da rotina MCOM023D
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
=================================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTA103MNU
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/06/2018
Descrição---------: PE pra adicionar itens no menu da browse de documento de entrada - Chamado 23086
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MTA103MNU()

aAdd(aRotina,{"Excluir (Italac)"             , "U_ITEXCNF()", 3, 5, 0, nil})//"Excluir"
aAdd(aRotina,{'Titulos Amarrados de Impostos', 'U_CTITFIN'  , 0, 5, 0, nil})
aAdd(aRotina,{'Reenvio WorkFlow'             , 'U_ITEnvia'  , 0, 5, 0, nil})//Essa função esta no rdmake MT103FIM.PRW
aAdd(aRotina,{'Inf. Chave CT-e'              , 'U_MCOM018'  , 0, 4, 0, nil})
aAdd(aRotina,{'Danfe/Dacte'              	 , 'U_MCOM023D'  , 0, 4, 0, nil})

Return

/*
===============================================================================================================================
Programa--------: ITEnvia()
Autor-----------: Alex Wallauer
Data da Criacao-: 13/08/2019
Descrição-------: Monta e dispara o WF para avisar o solicitante de uma compra que seu produto já chegou na empresa
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ITEnvia()

If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   FWMsgRun( ,{|oProc| U_EnviaWF4(.T.,oProc) },"Aguarde...","Enviando Workflow 4-NF fora do prazo...")
EndIf

If SF1->F1_TIPO == "N" 
   FWMsgRun( ,{|oProc| U_EnviaWF3(.T.,oProc) },"Aguarde...","Enviando Workflow 3-Solicitante...")
EndIf	

Return

/*
===============================================================================================================================
Programa----------: ITEXCNF
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/06/2018
Descrição---------: Rotina italac de exclusão de documento de entrada
Parametros--------: oproc - objeto da barra de processamento
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ITEXCNF()

FWMsgRun(, { |oproc| U_ITEXCNFP(oproc)}, 'Aguarde...','Iniciando exclusão de nota de entrada...')

Return .T.

User Function ITEXCNFP(oproc)

Local _lRet := .T.
Private _lcanc := .F.

BEGIN TRANSACTION

//Estorna transferências de leite cru

//Localiza movimento de estorno
SD3->(DBSetOrder(13)) //D3_FILIAL + D3_CHAVEF1
If SD3->(DBSeek(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO)) 
 	While AllTrim(SD3->D3_FILIAL + SD3->D3_CHAVEF1) == AllTrim(SF1->F1_FILIAL+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_TIPO)
 		If SD3->D3_ESTORNO != 'S'
 			//Faz estorno
 			_ddataori := ddatabase
 			ddatabase := SD3->D3_EMISSAO
 			aAuto := {}   
 			lMsErroAuto  := .F.                       
 			MSExecAuto({|x,y| mata261(x,y)},aAuto,6) 
			
 			ddatabase := _ddataori
			
 			If lMsErroAuto .Or. SD3->D3_ESTORNO != 'S'  
 				U_ITMsg( 'Existe transferência de leite cru a granel e não foi possível estornar', 'MTA103MNU001',;
				'Realize o estorno da transferência manualmente -> DOC ' + SD3->D3_DOC  , 1 )
				_lRet := .F.			
			EndIf
		Else
		     SD3->(DBSkip())
		EndIf
	EndDo
EndIf

If _lRet
	oproc:cCaption := ("Executando exclusão de documento de entrada...")
	ProcessMessages()
	_lRet := A103NFiscal("SF1",SF1->(Recno()),5)  //Chama tela de exclusão padrão
EndIf

If !_lRet .Or. _lcanc 
	disarmtransaction() //Se falhou estorno de transferência ou não completou eexclusão do documento de entrada faz rollback
EndIf

END TRANSACTION

//Garante final da transação e unlock de registros
If !IsInCallStack("U_MGLT009") .And. SuperGetMV("IT_F1UNL",.T.,.T.)
	Dbcommit()
	Dbcommitall()
	Dbunlock()
EndIf

Return

/*
===============================================================================================================================
Programa----------: CTITFIN
Autor-------------: Josué Danich Prestes
Data da Criacao---: 19/06/2018
Descrição---------: Tela consulta titulo amarrados de impostos  
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function CTITFIN()

Local _cTitPai   := SF1->F1_SERIE+SF1->F1_DOC+"  NF "+SF1->F1_FORNECE+SF1->F1_LOJA     
Local _cPrefixo  := SF1->F1_SERIE
Local _cFil      := SF1->F1_FILIAL  
Local _FiltraSE2 := "E2_FILIAL ='"+_cFil+"' And E2_TITPAI = '"+_cTitPai+"' And E2_PREFIXO = '"+_cPrefixo+"'"       

Private CCADASTRO:=OemToAnsi("Titulos de Impostos")
Private aRotina := {}    
Private aFixe :=   { 	{ "Prefixo"   , "E2_PREFIXO"},;
						{ "Numero"    , "E2_NUM" },;
						{ "Parcela"   , "E2_PARCELA"},;
						{ "Tipo"      , "E2_TIPO"},;
						{ "Natureza"  , "E2_NATUREZ"},;   
						{ "Fornecedor", "E2_FORNECE"},;
						{ "Loja"      , "E2_LOJA"},;
						{ "Nome"      , "E2_NOMFOR"},;
						{ "Emissao"   , "E2_EMISSAO"},;
						{ "Vencimento Real", "E2_VENCREA"},;
						{ "Valor"     , "E2_VALOR"} }

	
aAdd( aRotina, {"Pesquisar","AxPesqui",0,1})
aAdd( aRotina, {"Visualizar","AxVisual",0,2})

DBSelectArea("SE2")   

mBrowse( 6, 1,22,75,"SE2",aFixe,,,,,,,,,,,,,_FiltraSE2)    

Return(.T.)
