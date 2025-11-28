/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
Lucas Borges  |22/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Lucas Borges  |24/09/2025| Chamado 52242, 52243. Corrigida passagem do parâmetro
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: EMP650
Autor-------------: Josué /Danich Prestes
Data da Criacao---: 27/10/2015
Descrição---------: Pe para ajustar empenhos na inclusão de op antes da tela de visualização dos empenhos - Chamado 12006
Parametros--------: _ntipo -	0 Função chamada a partir do PE padrão do Protheus
									1 - Função chamada a partir da validação ou menu da alteração de empenho multiplo
									2 - Função chamada a partir da validação ou menu da alteração de empenho simples
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function EMP650(_ntipo)

Local _aArea		:= FWGetArea()
Local _oDlg1		:= nil
Local _oPanel		:= nil
Local _nOpc1    	:= 0
Local _cCreme		:= SuperGetMV("IT_PCREME",.F.,"08000000007;08000000033" )
Local _lachou  	:= .F.
Local _oBrowse 	:= nil  
Local _nni			:= 1    
Local _nPosCod   	:= 0
Local _nPosQuant	:= 0
Local _nPosoRI	:= 0

Private _alist	:= {}

Default _ntipo := 0 // 0 vem do ponto de entrada do padrão, 1 vêm do menu da tela de alteração de empenhos multiplo,
					  // 2 vem da tela de alteração de empenho simples

If _ntipo == 0
	_nPosCod   	:= aScan(aheader,{|x| AllTrim(x[2])=="G1_COMP"})
	_nPosQuant		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_QUANT"})
	_nPosGor		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_PGOR"})
ElseIf _ntipo == 1
	_nPosCod   	:= aScan(aheader,{|x| AllTrim(x[2])=="D4_COD"})
	_nPosQuant		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_QUANT"})
	_nPosOri		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_QTDEORI"})
	_nPosGor		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_PGOR"})
	_nPosArma 		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_LOCAL"})
	
	//verifica se está mexendo em creme ou leite in natura, se não retorna .T.
	_lTela := ( ( AllTrim(acols[n][_nPosArma]) == '03' .Or. AllTrim(acols[n][_nPosArma]) == '01') .And. AllTrim(Posicione("SB1",1,xFilial("SB1")+ AllTrim(acols[n][_nPosCod]),"B1_UM")) == "L" )
	If !_lTela
		Return .T.
	EndIf 
ElseIf _ntipo == 2
	FWAlertWarning("Alteração de qtde de empenhos em OP deve ser realizada na tela de alt. empenhos multiplos","EMP65001")
	Return .F.
EndIf

//======================================================================================================
// Verifica se tem produto creme com quantidade negativa na composição em registro não deletado do acols                   
//======================================================================================================
For _nNi := 1 to Len(acols)
	If AllTrim(acols[_nNi][_nPosCod ]) $ AllTrim(_cCreme) .And. acols[_nNi][_nPosQuant] < 0 .And. !(acols[_nni][Len(acols[_nni])])
		_lachou := .T.
	EndIf
Next _nNi

//===================================================================================================
// Se achou produto creme com qtde negativa é leite padronizado e abre a tela de desmontagem                 
//===================================================================================================
If _lachou 

	//===============================================================
	// Cria o alist para insercao dos dados selecionados. 
	//===============================================================
	FWMsgRun(,{||CursorWait(), CriaArq(_ntipo), CursorArrow()},"Aguarde....","Criando arquivo temporario...")
	
	//===============================================================
	// Ordena matriz do browse                           
	//===============================================================
	_alist := aSort(_alist, , , { | x,y | x[9] < y[9] } ) 
	
	//===============================================================
	// Cria a tela para ajuste do empenho semi automatizada                           
	//===============================================================
	DEFINE MSDIALOG _oDlg1 TITLE OemToAnsi("Calculo de desmontagem") From 0,0 To 300,900 OF oMainWnd PIXEL

	_oPanel       := TPanel():New(30,0,'',_oDlg1,, .T., .T.,, ,0,20,.T.,.T. )
	
	@ 0.8 ,00.8 Say OemToAnsi("OP:   " + AllTrim(SC2->C2_NUM) + "  /  " + AllTrim(SC2->C2_ITEM) + "  /  " + AllTrim(SC2->C2_SEQUEN)) OF _oPanel
	@ 0.8 ,30.8 Say OemToAnsi("PRODUTO:   " + AllTrim(SC2->C2_PRODUTO) + "  -  " + AllTrim(SC2->C2_I_DESC)) OF _oPanel

	_oBrowse := TCBrowse():New( 030 , 003, 400, 60,,; 
	{"Produto","Tipo","Descricao"},{40,60,140},;          
	_oDlg1,,,,,{||},,,,,,,.F.,,.T.,,.F.,,, )
	
	_oBrowse:AddColumn(TCColumn():New("Produto"   ,{ || _aList[_oBrowse:nAt,1] },"@!"       			,,,"RIGHT",050,.F.,.F.,,,,,)) 
	_oBrowse:AddColumn(TCColumn():New("Tipo"      ,{ || _aList[_oBrowse:nAt,2] },"@!"      				,,,"LEFT" ,060,.F.,.F.,,,,,)) 
	_oBrowse:AddColumn(TCColumn():New("Descricao" ,{ || _aList[_oBrowse:nAt,3] },"@!"       			,,,"LEFT" ,150,.F.,.F.,,,,,)) 	
	_oBrowse:AddColumn(TCColumn():New("Gordura"   ,{ || _aList[_oBrowse:nAt,4] },"@E 999.99"			,,,"RIGHT",030,.F.,.F.,,,,,))  
	_oBrowse:AddColumn(TCColumn():New("Quantidade",{ || _aList[_oBrowse:nAt,5] },"@E 999,999,999.99"	,,,"RIGHT",050,.F.,.F.,,,,,))  
	_oBrowse:AddColumn(TCColumn():New("Rateio    ",{ || _aList[_oBrowse:nAt,6] },"@E 999.99"			,,,"RIGHT",030,.F.,.F.,,,,,))  
	_oBrowse:AddColumn(TCColumn():New("    "      ,{ || _aList[_oBrowse:nAt,7] },           			,,,"RIGHT",050,.F.,.F.,,,,,))  
	
	//===================================================================================================
	// Seta o vetor a ser utilizado                                                                      
	//===================================================================================================
	_oBrowse:SetArray(_aList) 
   
	//===================================================================================================
	// Monta a linha a ser exibida no Browse                                                             
	//===================================================================================================
	_oBrowse:bLine := {||{ _aList[_oBrowse:nAt,01],;
	_aList[_oBrowse:nAt,02],; 
	_aList[_oBrowse:nAt,03],; 
	_aList[_oBrowse:nAt,04],; 
	_aList[_oBrowse:nAt,05],;
	_aList[_oBrowse:nAt,06],;
	_aList[_oBrowse:nAt,07] } }
	
	//===================================================================================================		
	// Evento de DuploClick (leva para rotina de edição e atualização do browse)                                
	_oBrowse:bLDblClick := {|| atuacel(_aList,_oBrowse) }                                                
	//===================================================================================================
	
	ACTIVATE MSDIALOG _oDlg1 ON INIT ( EnchoiceBar(_oDlg1,{||( IIf(validatud(),(_nopc1:=1,_oDlg1:End()),) ) },{|| (_nopc1 := 0,_oDlg1:End()) })  , _oPanel:Align := CONTROL_ALIGN_TOP  , _oBrowse:Align := CONTROL_ALIGN_ALLCLIENT  ) CENTERED//,,,,,,,,.F. 
	
	//===================================================================================================
	//Após fechar janela atualiza acols da tela de empenhos que vai abrir após este ponto de entrada     
	//===================================================================================================
	If _nopc1 = 1
		For _nni := 1 to Len(acols)  
			If !(acols[_nni][Len(acols[_nni])]) //se não For registro deletado   
				_nposlis := aScan( _alist,{|_alist|AllTrim(_alist[1])== AllTrim(acols[_nni][_nposcod])})
				If _nposlis > 0
					acols[_nni][_nposQuant] := _alist[_nposlis][5] * IIf(_alist[_nposlis][9]==3,-1,1)  //se For creme manda quantidade negativa
					acols[_nni][_nPosGor]   := _alist[_nposlis][4] 
					If _ntipo == 1 // vem da tela de alteração de empenho então altera também o d4_qtdeori
						acols[_nni][_nposOri] := _alist[_nposlis][5] * IIf(_alist[_nposlis][9]==3,-1,1)  //se For creme manda quantidade negativa
					EndIf	
				EndIf
			EndIf  
		Next _nni
		//Log de utilização
		U_ITLOGACS()
	EndIf
EndIf

FWRestArea(_aArea)

Return .T.

/*
===============================================================================================================================
Programa----------: CriaArq
Autor-------------: Josué Danich Prestes
Data da Criacao---: 07/10/2015
Descrição---------: Funcao para criacao do arquivo temporario. 
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function CriaArq(_ntipo)

Local _nNi			:= 1 
Local _nPosCod   	:= 0
Local _nPosQuant	:= 0
Local _nPosDescr 	:= 0
Local _nPosArma 	:= 0
Local _ctipo		:= ""
Local _ngord		:= 0
Local _nrateio		:= 0
Local _nqtcreme		:= 0
Local _nqtnat		:= 0
Local _nquant		:= 0
Local _nordem		:= 0
Local _cLint		:= SuperGetMV("IT_LINT" ,.F.,"08000000001;08000000051;08000000028,08000000008" )
Local _cLdes		:= SuperGetMV("IT_LDES" ,.F.,"08000000002;08000000050" )
Local _cLsemi		:= SuperGetMV("IT_LSEMI",.F.,"08000000003;08000000055" )
Local _cCreme		:= SuperGetMV("IT_PCREME",.F.,"08000000007;08000000033" )
Local _cnatura		:= SuperGetMV("IT_PNATUR",.F.,"08000000035;08000000036;08000000004;08000000048;08000000039" )
Local _npgnat		:= 0										   
Local _npgcrm		:= 0

If _ntipo == 0 // se veio do ponto de entrada padrão
	_nPosCod   	:= aScan(aheader,{|x| AllTrim(x[2])=="G1_COMP"})
	_nPosQuant		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_QUANT"})
	_nPosDescr 	:= aScan(aheader,{|x| AllTrim(x[2])=="B1_DESC"})
	_nPosArma 		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_LOCAL"})
ElseIf _ntipo == 1 //se veio da tela de alteração de empenhos
	_nPosCod   	:= aScan(aheader,{|x| AllTrim(x[2])=="D4_COD"})
	_nPosQuant		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_QUANT"})
	_nPosArma 		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_LOCAL"})
	_nPosGor		:= aScan(aheader,{|x| AllTrim(x[2])=="D4_I_PGOR"})
EndIf

_alist := {}
_nqtdes := 0

//=======================================================================================
// Carrega dados do acols                           
//=======================================================================================
For _nni := 1 to Len(acols)
	If !( acols[_nni][Len(acols[_nni])] ) .And. acols[_nni][_nPosQuant] <> 0
		//=======================================================================================
		// Só carrega se For creme ou leite in natura e determina valores default                           
		//=======================================================================================
		If AllTrim(acols[_nni][_nPosCod]) $ AllTrim(_cCreme) .Or. AllTrim(acols[_nni][_nPosCod]) $ AllTrim(_cNatura)
			If acols[_nni][_nPosQuant] < 0 .And. AllTrim(acols[_nni][_nPosCod]) $ AllTrim(_cCreme)
				_ctipo 	:= "CREME"
				If _ntipo == 0 //veio do ponto de entrada de inclusão de op preenche com zero para forçar digitação
					_ngord		:= 0
				ElseIf _ntipo == 1 //veio da alteração de empenho, preenche com valor atual para visualização
					_ngord 	:= acols[_nni][_nPosGor]
					_npgcrm	:= _ngord
				EndIf
				_nrateio 	:= (( acols[_nni][_nPosQuant] / ( SC2->C2_QUANT + ( -1 * acols[_nni][_nPosQuant] ) ) ) * -1) * 100
				_nqtcreme	:= acols[_nni][_nPosQuant] * -1
				_nquant 	:= _nqtcreme
				_nordem	:= 3
			ElseIf AllTrim(acols[_nni][_nPosCod]) $ AllTrim(_cNatura)
				_ctipo 	:= "LEITE IN NATURA"
				If _ntipo == 0 //veio do ponto de entrada de inclusão de op preenche com zero para forçar digitação
					_ngord		:= 0
				ElseIf _ntipo == 1 //veio da alteração de empenho, preenche com valor atual para visualização
					_ngord 	:= acols[_nni][_nPosGor]
					_npgnat	:= _ngord
				EndIf
				_nrateio 	:= 100
				_nquant	:= acols[_nni][_nPosQuant]
				_nqtnat := _nquant
				_nordem	:= 1
			EndIf
			aAdd(_alist,{AllTrim(acols[_nni][_nPosCod]),_ctipo,Posicione("SB1",1,xFilial("SB1")+ AllTrim(acols[_nni][_nPosCod]),"B1_DESC"),_ngord,_nquant,_nrateio, " "," ",_nordem})
		EndIf
		
		//==============================================================================================
		//Inclui leite desnatado e guarda valor para descontar do leite in natura
		//==============================================================================================
		If AllTrim(acols[_nni][_nPosCod]) $ AllTrim(_cLdes) 
			_nrateio 	:= 100
			_nquant	:= acols[_nni][_nPosQuant]
			_nqtdes := _nquant
			_nordem	:= 2
			_ctipo 	:= "LEITE DESNATADO"
			_ngord  := 0
			aAdd(_alist,{AllTrim(acols[_nni][_nPosCod]),_ctipo,Posicione("SB1",1,xFilial("SB1")+ AllTrim(acols[_nni][_nPosCod]),"B1_DESC"),_ngord,_nquant,_nrateio, " "," ",_nordem})
		EndIf
	EndIf
Next _nni

//=======================================================================================
// Acrescenta produto final da OP que será o leite desmontado                           
//=======================================================================================

//inclusão de op
If _ntipo == 0
	_ngord := 3
    _aGord:= "{"+AllTrim(SuperGetMV("IT_PERGORD",.F.,"3.1,1.0,0.05" ))+"}"
    _aGord:= &_aGord

	If AllTrim(SC2->C2_PRODUTO) $ _cLint //Leite integral
		_ngord := _aGord[1]//3.1
	EndIf

	If AllTrim(SC2->C2_PRODUTO) $ _cLsemi //Leite semidesnatado
		_ngord := _aGord[2]//1.0
	EndIf

	If AllTrim(SC2->C2_PRODUTO) $ _cLdes //Leite desnatado
		_ngord := _aGord[3]//0.05
	EndIf

//alteração de empenho
ElseIf _ntipo == 1
	_nratcrm 	:= _nqtcreme / _nqtnat  //rateio do creme
	_ngord 	:= _npgnat - ( _nratcrm * _npgcrm ) //gordura do leite desmontado
EndIf

aAdd(_alist,{AllTrim(SC2->C2_PRODUTO),"LEITE DESMONTADO",AllTrim(SC2->C2_I_DESC),_ngord,SC2->C2_QUANT,(SC2->C2_QUANT / ( SC2->C2_QUANT + _nqtcreme )) * 100, " "," ",4})
		
Return

/*
===============================================================================================================================
Programa----------: Atuacel
Autor-------------: Josué Danich Prestes
Data da Criacao---: 08/10/2015
Descrição---------: Funcao editar % de gordura e atualizar demais campos
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function atuacel(_aList,_oBrowse)

Local _npgornat := 0 // % gordura leite natural
Local _npgorcrm := 0 // % gordura creme
Local _npgorpad := 0 // % gordura leite padronizado
Local _npgordes := 0 // % gordura leite desnatado
Local _nvolnat	:= 0 // volume leite natural
Local _nvolcrm	:= 0 // volume creme
Local _nvolpad	:= 0 // volume leite padronizado
Local _nvoldes	:= 0 // volume leite desnatado
Local _nratnat	:= 0 // rateio leite natural
Local _nratcrm	:= 0 // rateio creme
Local _nratpad	:= 0 // rateio leite padronizado
Local _nratdes	:= 0 // rateio leite desnatado
Local _nposori	:= _oBrowse:nAt //posição original no browse
Local _nmaxcru	:= SuperGetMV("IT_MAXCRU",.F.,4)
Local _nmincru	:= SuperGetMV("IT_MINCRU",.F.,0.5)
Local _nmaxcrm	:= SuperGetMV("IT_MAXCRM",.F.,100)
Local _nmincrm	:= SuperGetMV("IT_MINCRM",.F.,10)
Local _nmaxpdr	:= SuperGetMV("IT_MAXPDR",.F.,4)
Local _nminpdr	:= SuperGetMV("IT_MINPDR",.F.,0.1)
Local _nposnat	:= aScan(_aList,{|x| AllTrim(x[2])=="LEITE IN NATURA"})
Local _nposdes	:= aScan(_aList,{|x| AllTrim(x[2])=="LEITE DESNATADO"})
Local _nposcre	:= aScan(_aList,{|x| AllTrim(x[2])=="CREME"})
Local _npospad	:= aScan(_aList,{|x| AllTrim(x[2])=="LEITE DESMONTADO"})  
Local _npvalori	:= _aList[_oBrowse:nAt][4] //valor original do campo
Local _npvalor2	:= _aList[_oBrowse:nAt][6] //valor original do campo
Local _npropn	:= 0
Local _npropd	:= 0

If _nposori == _nposdes  //Não edita gordura do leite desnatado, abre edição de célula do rateio

	//edita a célula
	lEditCell(_aList,_oBrowse,"@E 999.99",6)
	
	//posiciona na primeira linha, lê valores do leite cru
	_npgornat 		:= 	_aList[_nposnat][4]
	_nvolnat		:=	_aList[_nposnat][5]
	_nratnat		:=	_aList[_nposnat][6]

	//posiciona na segunda linha, lê valores do creme
	_npgorcrm 		:= 	_aList[_nposcre][4]
	_nvolcrm		:=	_aList[_nposcre][5]
	_nratcrm		:=	_aList[_nposcre][6]

	//posiciona na terceira linha, lê valores do leite padronizado
	_npgorpad 		:= 	_aList[_npospad][4]
	_nvolpad		:=	_aList[_npospad][5]
	_nratpad		:=	_aList[_npospad][6]

	//posiciona na  linha, lê valores do leite desnatado
	If _nposdes > 0
		_npgordes 		:= 	_aList[_nposdes][4]
		_nvoldes		:=	_aList[_nposdes][5]
		_nratdes		:=	_aList[_nposdes][6]
	EndIf

	_ngordisp := (_aList[_nposnat][4] * _aList[_nposnat][5])/100
	_nleidisp := ((100-_aList[_nposnat][4]) * _aList[_nposnat][5])/100

	If _nposdes > 0
		_nleidisp += _aList[_nposdes][5]
	EndIf

	_ngordnec := (_aList[_npospad][4] * _aList[_npospad][5])/100
	
	//valida contra valor negativo 
	If _aList[_oBrowse:nAt][6] < 0 
		FWAlertWarning("% Rateio não pode ser negativo!","EMP65002")
		_aList[_oBrowse:nAt][6] := _npvalor2
		Return
	EndIf
	
	//Valida se tem gordura suficiente para diluir no leite desnatado e pelo menos gerar o padronizado com zero de creme
	_nleitot := _aList[_nposnat][5] + _aList[_nposdes][5]
	_npropn := 100 - _aList[_nposdes][6]
	_npropd := _aList[_nposdes][6]
	_nvoln := _nleitot * (_npropn/100)
	_nvold := _nleitot * (_npropd/100)
	_ngordisp := (_nvoln * _aList[_nposnat][4])/100 
	
	If _ngordisp < _ngordnec

		FWAlertWarning("Gordura do leite in natura com esse rateio não é suficiente para montar o leite padronizado!"+;
				"Gordura disponível no leite in natura: " + transform(_ngordisp,"@E 999,999,999.99") + chr(10)+chr(13) +;
				"Gordura necessária para o leite padronizado: " + transform(_ngordnec,"@E 999,999,999.99"),"EMP65003")
	
		_aList[_oBrowse:nAt][6] := _npvalor2
		Return
	EndIf
	
	//Recalcula volumes do leite in natura e leite desnatado
	_nleitot := _aList[_nposnat][5] + _aList[_nposdes][5]
	_aList[_nposnat][6] := 100 - _aList[_nposdes][6]
	_aList[_nposnat][5] := _nleitot * (_aList[_nposnat][6]/100)
	_aList[_nposdes][5] := _nleitot * (_aList[_nposdes][6]/100)
	_npropn := _aList[_nposnat][6]
	_npropd := _aList[_nposdes][6]
	
	//Refaz leitura de variaveis para calculo posterior
		//posiciona na primeira linha, lê valores do leite cru
	_npgornat 		:= 	_aList[_nposnat][4]
	_nvolnat		:=	_aList[_nposnat][5]
	_nratnat		:=	_aList[_nposnat][6]

	//posiciona na segunda linha, lê valores do creme
	_npgorcrm 		:= 	_aList[_nposcre][4]
	_nvolcrm		:=	_aList[_nposcre][5]
	_nratcrm		:=	_aList[_nposcre][6]

	//posiciona na terceira linha, lê valores do leite padronizado
	_npgorpad 		:= 	_aList[_npospad][4]
	_nvolpad		:=	_aList[_npospad][5]
	_nratpad		:=	_aList[_npospad][6]

	//posiciona na  linha, lê valores do leite desnatado
	If _nposdes > 0
		_npgordes 		:= 	_aList[_nposdes][4]
		_nvoldes		:=	_aList[_nposdes][5]
		_nratdes		:=	_aList[_nposdes][6]
	EndIf

	_ngordisp := (_aList[_nposnat][4] * _aList[_nposnat][5])/100
	_nleidisp := ((100-_aList[_nposnat][4]) * _aList[_nposnat][5])/100

	If _nposdes > 0
		_nleidisp += _aList[_nposdes][5]
	EndIf

	_ngordnec := (_aList[_npospad][4] * _aList[_npospad][5])/100
		
Else
	//edita a célula
	lEditCell(_aList,_oBrowse,"@E 999.99",4)

	//posiciona na primeira linha, lê valores do leite cru
	_npgornat 		:= 	_aList[_nposnat][4]
	_nvolnat		:=	_aList[_nposnat][5]
	_nratnat		:=	_aList[_nposnat][6]

	//posiciona na segunda linha, lê valores do creme
	_npgorcrm 		:= 	_aList[_nposcre][4]
	_nvolcrm		:=	_aList[_nposcre][5]
	_nratcrm		:=	_aList[_nposcre][6]

	//posiciona na terceira linha, lê valores do leite padronizado
	_npgorpad 		:= 	_aList[_npospad][4]
	_nvolpad		:=	_aList[_npospad][5]
	_nratpad		:=	_aList[_npospad][6]

	//posiciona na  linha, lê valores do leite desnatado
	If _nposdes > 0
		_npgordes 		:= 	_aList[_nposdes][4]
		_nvoldes		:=	_aList[_nposdes][5]
		_nratdes		:=	_aList[_nposdes][6]
	EndIf

	_ngordisp := (_aList[_nposnat][4] * _aList[_nposnat][5])/100
	_nleidisp := ((100-_aList[_nposnat][4]) * _aList[_nposnat][5])/100

	If _nposdes > 0
		_nleidisp += _aList[_nposdes][5]
	EndIf

	_ngordnec := (_aList[_npospad][4] * _aList[_npospad][5])/100

	//valida contra valor negativo 
	If _aList[_oBrowse:nAt][4] <= 0 
		FWAlertWarning("% Gordura não pode ser negativo ou zero!","EMP65004")
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

	//valida limites leite cru
	If (_aList[_oBrowse:nAt][4] < _nmincru .Or.  _aList[_oBrowse:nAt][4] > _nmaxcru) .And. _nposori == _nposnat
		FWAlertWarning("% Gordura do leite cru tem que estar entre " + AllTrim(Str(_nmincru)) + " e " + AllTrim(Str(_nmaxcru)) +"!","EMP65005")
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

	//valida limites creme
	If (_aList[_oBrowse:nAt][4] < _nmincrm .Or.  _aList[_oBrowse:nAt][4] > _nmaxcrm) .And. _nposori == _nposcre
		FWAlertWarning("% Gordura do creme tem que estar entre " + AllTrim(Str(_nmincrm)) + " e " + AllTrim(Str(_nmaxcrm)) +"!","EMP65006")
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

	//valida limites leite padronizado
	If (_aList[_oBrowse:nAt][4] < _nminpdr .Or.  _aList[_oBrowse:nAt][4] > _nmaxpdr) .And. _nposori == _npospad
		FWAlertWarning("% Gordura do leite padronizado tem que estar entre " + AllTrim(Str(_nminpdr)) + " e " + AllTrim(Str(_nmaxpdr)) +"!","EMP65007")
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

	//Valida contra % gordura do leite padronizado  maior que a % de gordura no leite cru
	If _npgorpad > _npgornat
		FWAlertWarning("% Gordura do leite desmontado não pode ser maior que % de gordura do leite cru!","EMP65008")
		_oBrowse:nAt := _nposori
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

	//Valida se tem gordura suficiente para diluir no leite desnatado e pelo menos gerar o padronizado com zero de creme
	If _ngordisp < _ngordnec
		FWAlertWarning("% Gordura do leite in natura não é suficiente para montar o leite padronizado! "+;
				"Gordura disponível no leite in natura: " + transform(_ngordisp,"@E 999,999,999.99") + chr(10)+chr(13) +;
				"Gordura necessária para o leite padronizado: " + transform(_ngordnec,"@E 999,999,999.99"),"EMP65009")
		_oBrowse:nAt := _nposori
		_aList[_oBrowse:nAt][4] := _npvalori
		Return
	EndIf

EndIf

//faz cálculos sequenciais para atualizar as demais células

//Com leite desnatado
If _nposdes > 0

	_oBrowse:nAt := _nposcre //muda para linha do creme
	_ngdcreme := _ngordisp - _ngordnec
	If _aList[_oBrowse:nAt][4] > 0
		_nvolcreme := _ngdcreme /  (_aList[_oBrowse:nAt][4]/100)
	Else
		_aList[_oBrowse:nAt][4] := 40
		_nvolcreme := _ngdcreme /  (_aList[_oBrowse:nAt][4]/100)
	EndIf
	
	_aList[_oBrowse:nAt][5] := _nvolcreme

	_oBrowse:nAt := _nposnat //muda para linha do leite in natura
	_nvollei := _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
	_nvolpad := _aList[_oBrowse:nAt][5]

	_oBrowse:nAt := _nposdes //muda para linha do leite desnatado
	_nvollei += _aList[_oBrowse:nAt][5]

	_oBrowse:nAt := _npospad //muda para linha do leite padronizado
	_nvolnec := _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
	_oBrowse:nAt := _nposcre //muda para linha do creme
	_nvolnec += _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
	
	_nvoldif := _nvolnec - _nvollei
	_oBrowse:nAt := _nposdes //muda para linha do leite desnatado
	_aList[_oBrowse:nAt][5] := _aList[_oBrowse:nAt][5] + _nvoldif
	_nvoldes := _aList[_oBrowse:nAt][5]
	_aList[_oBrowse:nAt][6] := (_nvoldes/(_nvoldes+_nvolpad))*100
	
	_oBrowse:nAt := _nposnat //muda para linha do leite in natura
	_aList[_oBrowse:nAt][6] := (_nvolpad/(_nvoldes+_nvolpad))*100
	
	
	//Se tem proporção desejada faz Loop de aproximação até chegar na proporção desejada
	If 	_npropn > 0 
	
		_nnu := 1
		
		While _nnu < 20 .And. _aList[_nposnat][6] != _npropn .And. _aList[_nposdes][6] != _npropd
	
			_aList[_nposdes][6] := _npropd
	
			//Recalcula volumes do leite in natura e leite desnatado
			_nleitot := _aList[_nposnat][5] + _aList[_nposdes][5]
			_aList[_nposnat][6] := 100 - _aList[_nposdes][6]
			_aList[_nposnat][5] := _nleitot * (_aList[_nposnat][6]/100)
			_aList[_nposdes][5] := _nleitot * (_aList[_nposdes][6]/100)
			_npropn := _aList[_nposnat][6]
			_npropd := _aList[_nposdes][6]
	
			//Refaz leitura de variaveis para calculo posterior
			//posiciona na primeira linha, lê valores do leite cru
			_npgornat 		:= 	_aList[_nposnat][4]
			_nvolnat		:=	_aList[_nposnat][5]
			_nratnat		:=	_aList[_nposnat][6]

			//posiciona na segunda linha, lê valores do creme
			_npgorcrm 		:= 	_aList[_nposcre][4]
			_nvolcrm		:=	_aList[_nposcre][5]
			_nratcrm		:=	_aList[_nposcre][6]

			//posiciona na terceira linha, lê valores do leite padronizado
			_npgorpad 		:= 	_aList[_npospad][4]
			_nvolpad		:=	_aList[_npospad][5]
			_nratpad		:=	_aList[_npospad][6]

			//posiciona na  linha, lê valores do leite desnatado
			If _nposdes > 0
				_npgordes 		:= 	_aList[_nposdes][4]
				_nvoldes		:=	_aList[_nposdes][5]
				_nratdes		:=	_aList[_nposdes][6]
			EndIf

			_ngordisp := (_aList[_nposnat][4] * _aList[_nposnat][5])/100
			_nleidisp := ((100-_aList[_nposnat][4]) * _aList[_nposnat][5])/100

			If _nposdes > 0
				_nleidisp += _aList[_nposdes][5]
			EndIf

			_ngordnec := (_aList[_npospad][4] * _aList[_npospad][5])/100
		
			_oBrowse:nAt := _nposcre //muda para linha do creme
			_ngdcreme := _ngordisp - _ngordnec
			If _aList[_oBrowse:nAt][4] > 0
				_nvolcreme := _ngdcreme /  (_aList[_oBrowse:nAt][4]/100)
			Else
				_aList[_oBrowse:nAt][4] := 40
				_nvolcreme := _ngdcreme /  (_aList[_oBrowse:nAt][4]/100)
			EndIf
	
			_aList[_oBrowse:nAt][5] := _nvolcreme

			_oBrowse:nAt := _nposnat //muda para linha do leite in natura
			_nvollei := _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
			_nvolpad := _aList[_oBrowse:nAt][5]

			_oBrowse:nAt := _nposdes //muda para linha do leite desnatado
			_nvollei += _aList[_oBrowse:nAt][5]

			_oBrowse:nAt := _npospad //muda para linha do leite padronizado
			_nvolnec := _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
			_oBrowse:nAt := _nposcre //muda para linha do creme
			_nvolnec += _aList[_oBrowse:nAt][5] * (1-(_aList[_oBrowse:nAt][4]/100))
	
			_nvoldif := _nvolnec - _nvollei
			_oBrowse:nAt := _nposdes //muda para linha do leite desnatado
			_aList[_oBrowse:nAt][5] := _aList[_oBrowse:nAt][5] + _nvoldif
			_nvoldes := _aList[_oBrowse:nAt][5]
			_aList[_oBrowse:nAt][6] := (_nvoldes/(_nvoldes+_nvolpad))*100
	
			_oBrowse:nAt := _nposnat //muda para linha do leite in natura
			_aList[_oBrowse:nAt][6] := (_nvolpad/(_nvoldes+_nvolpad))*100
			
			_nnu++
			
		EndDo
	EndIf

//Sem leite desnatado
Else
	_oBrowse:nAt := _nposcre //muda para linha do creme
	_aList[_oBrowse:nAt][6] := 100 * (( _npgornat - _npgorpad ) ) / _npgorcrm  //rateio do creme
	_nratcrm	:=	_aList[_oBrowse:nAt][6]

	_oBrowse:nAt := _npospad //muda para linha do leite padronizado
	_aList[_oBrowse:nAt][6] := 100 - _nratcrm  //rateio do leite padronizado
	_nratpad := _aList[_oBrowse:nAt][6]

	_oBrowse:nAt := _nposnat //muda para linha do leite in natura
	_aList[_oBrowse:nAt][5] := (_nvolpad / ( _nratpad / 100 )) - _nvoldes //volume do leite in natura
	_nvolnat	:= _aList[_oBrowse:nAt][5]

	_oBrowse:nAt := _nposcre //muda para linha do creme
	_aList[_oBrowse:nAt][5] := _nvolnat + _nvoldes - _nvolpad //volume do creme
	_nvolcrm := _aList[_oBrowse:nAt][5]

EndIf

_oBrowse:DrawSelect()

_oBrowse:GoTop()

Return

/*
===============================================================================================================================
Programa----------: Validatud
Autor-------------: Josué Danich Prestes
Data da Criacao---: 09/10/2015
Descrição---------: Funcao para validar todos os campos de gordura ao fechar a janela
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function Validatud()

Local _lRet 	:= .T.
Local _nni 	:= 1

For _nni := 1 to Len(_aList)
	If _alist[_nni][4] <= 0 .And. _lRet .And. _alist[_nni][2] != "LEITE DESNATADO"
		FWAlertWarning("% Gordura não pode ser negativo ou zero!","EMP65010")
		_lRet := .F.
	EndIf
Next _nni

Return _lRet
