/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |02/07/2018| Chamado 25362. Substituida exclusão dos complementos pela função ECompFis.
Lucas Borges  |31/07/2024| Chamado 48058. Incluída função para excluir movimento interno referente ao desconto Tetra Pak.
Lucas Borges  |02/10/2025| Chamado 51526. Modificada forma para recuperar a matrícula do usuário.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: SF2520E
Autor-----------: Tiago Correa Castro
Data da Criacao-: 08/02/2009
Descrição-------: Ponto de Entrada após a exclusão da Nota Fiscal de Saida.
Parametros------: cTabAux := Código da Tabela no SX5
----------------: nTamAux := Tamanho da Chave para o Retorno
Retorno---------: .T. - Compatibilidade com a utilização em F3
===============================================================================================================================
*/
User Function SF2520E

Local _aArea		:= FWGetArea()
Local _aAreaSF2		:= SF2->(FWGetArea())
Local _aAreaSC9		:= SC9->(FWGetArea())
Local _aAreaDAI		:= DAI->(FWGetArea())
Local _aAreaSD2		:= SD2->(FWGetArea())
Local _aAreaSC5		:= SC5->(FWGetArea())
Local _aAreaSC6		:= SC6->(FWGetArea())
Local aVetor		:= {}
Local _cPedido		:=  SF2->F2_I_PEDID

Private lMsErroAuto	:= .F.

//================================================================================
// Grava filial e matricula do usuario q esta fazendo a exclusao
// na tabela SF2 campo F2_I_UEXCL(Caracter 8)
//================================================================================
RecLock("SF2",.F.)
F2_I_UEXCL := FWSFAllUsers({__cUserID},{"USR_FILIAL"})[1][3]+FWSFAllUsers({__cUserID},{"USR_CODFUNC"})[1][3]
SF2->(MSUnLock())
SF2->(dbCommit())

//Exclui os complementos de notas fiscais de entrada e de saida com as informacoes necessarias ao Sped.
Processa( {|| U_ECompFis("S",SF2->F2_DOC,SF2->F2_SERIE,SF2->F2_CLIENTE,SF2->F2_LOJA) }, "Aguarde...", "Excluindo Complementos Fiscais...",.F.)

//================================================================================
//| Exluindo titulo no financeiro ref. ao valor do frete                         |
//================================================================================
DBSelectArea("ZZ2")
ZZ2->(DBSetOrder(2)) // ZZ2_FILIAL+ZZ2_CARGA
If ZZ2->(DBSeek(xFilial("ZZ2")+SF2->F2_CARGA))
			
	DBSelectArea("SE2")
	SE2->( DBOrderNickName("IT_RPA")) //E2_FILIAL+E2_PREFIXO+E2_TIPO+E2_NUM+E2_PARCELA+E2_FORNECE+E2_LOJA                                                                                               
	SE2->( DBSeek( xFilial("SE2") + "AUT" + "RPA" + ZZ2->ZZ2_RECIBO ) )
	
	While SE2->(!Eof()) .And. SE2->E2_FILIAL == xFilial("SE2") .And. SE2->E2_PREFIXO == "AUT" .And. SE2->E2_NUM == ZZ2->ZZ2_RECIBO

		If SE2->E2_TIPO == "RPA" .And. SE2->E2_SALDO == SE2->E2_VALOR
			   
			lMsErroAuto := .F. 
			
			DBSelectArea("SA2")
			SA2->(DBSetOrder(1))
			SA2->(DBSeek(xFilial("SA2")+SE2->E2_FORNECE+SE2->E2_LOJA))
			
			DBSelectArea("SE2")
			SE2->(DBSetOrder(1)) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
			
			aVetor :={	{"E2_PREFIXO"	,SE2->E2_PREFIXO			,Nil},;
						{"E2_NUM"		,SE2->E2_NUM				,Nil},;
						{"E2_PARCELA"	,SE2->E2_PARCELA			,Nil},;
						{"E2_TIPO"		,SE2->E2_TIPO				,Nil},;
						{"E2_NATUREZ"	,SE2->E2_NATUREZ			,Nil},;
						{"E2_ORIGEM"    ,"GERAZZ3"      			,Nil} }
						
			MSExecAuto({|x,y,z| Fina050(x,y,z)},aVetor,,5) //Exclusao
			
			If lMsErroAuto
				Mostraerro()
			EndIf
			
		EndIf
		
		DBSelectArea("SE2")
		SE2->(DBSetOrder(1)) //E2_FILIAL+E2_PREFIXO+E2_NUM+E2_PARCELA+E2_TIPO+E2_FORNECE+E2_LOJA
		SE2->(DBSkip())
		
	EndDo
	
	// Apaga os dados do arquivo ZZ3 quando a exclusao da NF por nota/carga(Deletando item da N.F.)
	DBSelectArea("ZZ3")
	ZZ3->(DBSetOrder(1)) //ZZ3_FILIAL+ZZ3_RECIBO+ZZ3_CARGA+ZZ3_DOC+ZZ3_SERIE
	ZZ3->(DBSeek(xFilial("ZZ3")+ZZ2->ZZ2_RECIBO+SF2->F2_CARGA))
	While ZZ3->(!Eof()) .And. ZZ3->ZZ3_FILIAL == xFilial("ZZ3") .And. ZZ3->ZZ3_RECIBO == ZZ2->ZZ2_RECIBO .And. ZZ3->ZZ3_CARGA == ZZ2->ZZ2_CARGA
		RecLock("ZZ3",.F.)
		Delete
		MSUnLock()
		ZZ3->(DBSkip())
	EndDo
	
	//Deleta ZZ2 caso a exclusao seja por carga(Cabecalho do recibo)
	If Upper(AllTrim(FunName())) == "MATA521B"
		If MV_PAR04 == 1 //Os Pedidos voltam a ficar em carteira desfazendo assim a Montagem da Carga
			DBSelectArea("ZZ2")
			RecLock("ZZ2",.F.)
			Delete
			MSUnLock()
		EndIf
	EndIf
EndIf

//================================================================================
//| Verifica a exclusão de impostos calculados no RPA Avulso/Faturamento de Carga|
//================================================================================
U_ExcIMP()			// 31/07/2014 - Alexandre - Chamada da função que retira os impostos da ZZ2

//================================================================================
//| Verifica a exclusão de Títulos de NCC                                        |
//================================================================================
U_ExcNcc()	// 07/02/2013 - Talita - Chamada da função responsavel por excluir os titulos de NCC

//Atualizar Status do Pedido 

lCart := MV_PAR04==1
	
DBSelectArea("SC5")
SC5->(DBSetOrder(1))//C5_FILIAL+C5_NUM
If SC5->(DBSeek(xFilial("SC5") + _cPedido ))
          
	SC5->(RecLock("SC5",.F.))
	If SC5->C5_I_TRCNF = "N"
		SC5->C5_I_STATU = IIf(lCart,"01","03")
	Else 
		If SC5->C5_I_FLFNC <> SC5->C5_FILIAL //PEDIDO FATURAMENTO
			SC5->C5_I_STATU = IIf(lCart,"14","15")			
		Else                  
			SC5->C5_I_STATU = "12"	//PEDIDO CARREGAMENTO
			SC5->C5_I_STATU = IIf(lCart,"12","13")						
		EndIf    
	EndIf
	SC5->( MSUnLock() )
 
EndIf    

If SF2->F2_CLIENTE == 'F00004' .And. SF2->F2_TIPO == "D"
	DescTetraS()
EndIf

FWRestArea(_aAreaSF2)
FWRestArea(_aAreaSC9)
FWRestArea(_aAreaDAI)
FWRestArea(_aAreaSD2)
FWRestArea(_aAreaSC5)
FWRestArea(_aAreaSC6)
FWRestArea(_aArea)

Return

/*
===============================================================================================================================
Programa--------: ExcIMP
Autor-----------: Alexandre Villar
Data da Criacao-: 15/12/2008
Descrição-------: Rotina que Processa a eliminação do cálculo de impostos da ZZ2 no momento da exclusão.
Parametros--------: Nenhum
Retorno-----------: .T. - Permite o estorno
------------------: .F. - Impede o estorno
===============================================================================================================================
*/
User Function ExcIMP()

DBSelectArea('ZZ2')
ZZ2->( DBSetOrder(2) )
If ZZ2->( DBSeek( SF2->( F2_FILIAL + F2_CARGA ) ) )
	ZZ2->( RecLock( 'ZZ2' , .F. ) )
		ZZ2->ZZ2_SEST	:= 0
		ZZ2->ZZ2_INSS	:= 0
		ZZ2->ZZ2_IRRF	:= 0
	ZZ2->( MSUnLock() )
EndIf

Return

/*
===============================================================================================================================
Programa--------: ExcNCC
Autor-----------: Talita Teixeira
Data da Criacao-: 07/02/2013
Descrição-------: Consulta para verificar se a nota possui titulos de ncc se sim excluir os mesmos.
Parametros------: Nenhum
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function ExcNcc

Local cNumero	:= SF2->F2_DOC
Local aExcNCC 	:= {}  

Private lMsErroAuto := .F.

DBSelectArea ("SE1")
SE1->(DBSetOrder(1))
SE1->(DBSeek(xFilial("SE1")+"DCT"+cNumero))

While SE1->(!Eof()) .And. SE1->E1_NUM = cNumero
	If SE1->E1_TIPO = "NCC"
		aExcNCC := {	{ "E1_FILIAL"	, SE1->E1_FILIAL	, NIL },;
						{ "E1_PREFIXO"	, "DCT" 			, NIL },;
						{ "E1_NUM"		, cNumero			, NIL } }

		MsExecAuto( {|x,y| FINA040(x,y) } , aExcNCC , 5 )  // 3 - Inclusao, 4 - Alteração, 5 - Exclusão

		If lMsErroAuto
				MostraErro()
		EndIf
	EndIf
	SE1->( DBSkip() )
EndDo

Return

/*
===============================================================================================================================
Programa----------: DescTetraS
Autor-------------: Lucas Borges Ferreira
Data da Criacao---: 31/07/2024
Descrição---------: Gera movimento interno para retornar o valor do desconto TetraPak do produto
Parametros--------: nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function DescTetraS

Local _aSD3 := GetArea("SD3")

Private lMsErroAuto := .F.

SD3->(DBSetOrder(16)) //D3_FILIAL + D3_CHAVEF2
If SD3->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE+SF2->F2_CLIENTE+SF2->F2_LOJA))
	While !SD3->(Eof()) .And. SD3->D3_FILIAL+SubStr(SD3->D3_CHAVEF2,1,22) == SF2->(F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA)
		If SD3->D3_ESTORNO # "S"
			MsExecAuto({|x,y,z| MatA241(x,y,z)},{},Nil,6)
			If lMsErroAuto
				FWAlertError("Erro ao gerar movimento interno referente ao desconto Tetra Pak. Favor acionar a TI.","SF2520E01")
				Mostraerro()
			EndIf
		EndIf
		SD3->(DBSkip())
	EndDo
EndIf
FWRestArea(_aSD3)

Return
