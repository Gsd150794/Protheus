/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
Lucas Borges  |22/09/2025| Chamado 52201. Corrigido erro nas querys ao realizar o replace no Else
Alex Wallauer |24/09/2025| Chamado 52151. Alteração da leitura dos parametros do ZP1 para o SX6
Igor Melgaço  |04/11/2025| Chamado 52432. Ajuste para corrigir impressão reptida do produto BEB LAC UHT CHOC Z LAC WHEY 250 ML(15G)
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _aSalvaCusMGCMS

/*
===============================================================================================================================
Programa----------: MEST009
Autor-------------: Josue Danich
Data da Criacao---: 04/12/2015
Descricao---------: Gestao de custo gerencial ( Chamado 12497 )
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
User Function MEST009()

Local _bProcess  	:= nil
Local _lRet		:= .F.
Local oProcess

Private lHtml := (GetRemoteType() == 5) //Valida se o ambiente é SmartClientHtmlLocal 
Private _cdir := GetTempPath()

If lHtml
   _cdir := "\data\Italac\MEST009\LOGS\"
EndIf

//VERIFICA PERMISSAO DE ACESSO
_lRet :=  U_ITVACESS( 'ZZL' , 3 , 'ZZL_GCUSTO' , "S" )

If !_lRet
	U_ITMsg('Usuario sem acesso à rotina de gestão de custos gerenciais!',"ATENÇÃO",;
			'Favor entrar em contato com o responsavel do Leite.',3)
	
	Return .F.
EndIf

//Cria perguntas de regras
PERGUNTE("MEST009",.F.)
_nTamInt:=Len(MV_PAR09)

_aItalac_F3:={}
aAdd(_aItalac_F3,{"MV_PAR12",,,,,"Planilhas disponiveis para Geração",2,U_MEST9Plan()} )//'LSTME9'
aAdd(_aItalac_F3,{"MV_PAR02","ZL5", ZL5->(FIELDPOS("ZL5_CODGRP"))                          ,{|| "["+ZL5->ZL5_TPCUST+"] "+ZL5->ZL5_DESGRP },{|| IIf(Empty(MV_PAR01),.T.,ZL5->ZL5_TPCUST $ AllTrim(MV_PAR01)) },"Grupo Custo do Leite",Len(ZL5->ZL5_CODGRP),, } )
aAdd(_aItalac_F3,{"MV_PAR09","SM2",{|| StrTran(StrZero(SM2->M2_MOEDA2,_nTamInt,2),".",",")},{|| DToC(SM2->M2_DATA)                       },{|| SM2->M2_DATA >=  MV_PAR05 .And. SM2->M2_DATA <= MV_PAR06     },"Taxas Moeda Dolar",_nTamInt,,1,.F. } )

Private _lGera1Pla:= .F.
Private _lGera2Pla:= .F.
Private _lGera3Pla:= .F.
Private _lGera4Pla:= .F.
Private _nTotdol  := 0
Private _aCusto04 := {}

While .T.

   //Cria interface principal
   _lLoop:=.F.
   Private oTProcess
   oProcess:= MsNewProcess():New({|_lEnd,oProcess| MEST009M(@oProcess, @_lEnd) },"Gestao de Custo Gerencial H.I.: "+TIME(),"Processando",.T.)      

   _bProcess    := {|O|If( MEST009K(O), oProcess:Activate() , _lLoop := .T. ) }
   TNewProcess():New( "MEST009", "Gestao de Custo Gerencial", _bProcess, "Rotina de geracao de dados de custos gerenciais","MEST009",,,,,,.T.)
   oProcess:=NIL
   DelClassIntf()
   If _lLoop//Se A função MEST009K() devolver .F. ou usuario abortar ou processsar normalmente dá o Loop para aparecer a tela novamente senão sai fora 
      Loop
   EndIf
   Exit//Botão cancela 
EndDo

Return .T.

/*
===============================================================================================================================
Programa----------: MEST009M
Autor-------------: Josue Danich
Data da Criacao---: 28/10/2014
Descricao---------: Processamento principal da Gestao de custo gerencial 
Parametros--------: _oself - Objeto da interface principal / _lEnd - Variavel de Cancelamento
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MEST009M(_oSelf,_lEnd)

Local _nRegZL6 := 0
Local _lRet		:= .F.
Local _lMensagem:=.F.

_oSelf:SetRegua1( 4 )
_oSelf:SetRegua2( 4 )
_oSelf:IncRegua1("Iniciando os trabalhos, Aguarde..." )
_oSelf:IncRegua2("Iniciando os trabalhos, Aguarde..." )

If Type("oTProcess") = "O" 
   oTProcess:SetRegua1( 2 )
   oTProcess:SetRegua2( 2 )
   oTProcess:IncRegua1("Ainda Processando, Aguarde..." )
   oTProcess:IncRegua2("Ainda Processando, Aguarde..." )
EndIf

_lEnd:= .F.

Private lPrim		:= .T.
Private _ntotlei 	:= 0
Private _nTotSoro   := 0
Private _atotlei	:= {}
Private _cFilsemSRX := ""
Private _cTimeIni   := Time()

MV_PAR09:=StrTran(LEFT(MV_PAR09,_nTamInt),",",".")
Private _nTotdol := Val(MV_PAR09)
Private _aFactoMike:={}
aAdd(_aFactoMike,{"08000000039",1.0350,0,'x'})//Leite Cru: Quando o código do leite For 08000000039, fazer a conversão da quantidade encontrada * 1,035

aAdd(_aFactoMike,{"08000000001",1.0313,0,'x'})//Leite Integral: Quando o código do leite For 08000000001;08000000051, fazer a conversão da quantidade encontrada * 1,0313
aAdd(_aFactoMike,{"08000000051",1.0313,0,'x'})//Leite Integral: Quando o código do leite For 08000000001;08000000051, fazer a conversão da quantidade encontrada * 1,0313

aAdd(_aFactoMike,{"08000000073",1.0344,0,'x'})//Leite Semi: Quando o código do leite For 08000000073;08000000003;08000000057, fazer a conversão da quantidade encontrada * 1,0344
aAdd(_aFactoMike,{"08000000003",1.0344,0,'x'})//Leite Semi: Quando o código do leite For 08000000073;08000000003;08000000057, fazer a conversão da quantidade encontrada * 1,0344
aAdd(_aFactoMike,{"08000000057",1.0344,0,'x'})//Leite Semi: Quando o código do leite For 08000000073;08000000003;08000000057, fazer a conversão da quantidade encontrada * 1,0344

aAdd(_aFactoMike,{"08000000074",1.0344,0,'x'})//Leite Desnatado: Quando o código do leite For 08000000074;08000000002, fazer a conversão da quantidade encontrada * 1,0344
aAdd(_aFactoMike,{"08000000002",1.0344,0,'x'})//Leite Desnatado: Quando o código do leite For 08000000074;08000000002, fazer a conversão da quantidade encontrada * 1,0344

aAdd(_aFactoMike,{"08140000001",1.0320,0,'08000000028'})//Leite em pó Integral: As quantidade de leite em pó nos códigos: 08140000001;00020010501;00020010533 Após encontrar as quantidade de leite em pó, convertemos para o Rendimento em LTs, que é a quantidade*8,3. Após isso, convertemos novamente de LTS P/ KG, o resultado*1,032
aAdd(_aFactoMike,{"00020010501",1.0320,0,'08000000028'})//--Leite em pó Integral: As quantidade de leite em pó nos códigos: 08140000001;00020010501;00020010533 Após encontrar as quantidade de leite em pó, convertemos para o Rendimento em LTs, que é a quantidade*8,3. Após isso, convertemos novamente de LTS P/ KG, o resultado*1,032

aAdd(_aFactoMike,{"00020020533",1.0320,0,'08000000050'})//Leite em pó Desnatado: As quantidade de leite em pó nos códigos:00020020533;08140000002;00020020501 Após encontrar as quantidades de leite em pó, convertemos para o Rendimento em LTs, que é a quantidade*10,7. Após isso, convertemos novamente de LTS P/ KG, o resultado*1,032
aAdd(_aFactoMike,{"08140000002",1.0320,0,'08000000050'})//--Leite em pó Desnatado: As quantidade de leite em pó nos códigos:00020020533;08140000002;00020020501 Após encontrar as quantidades de leite em pó, convertemos para o Rendimento em LTs, que é a quantidade*10,7. Após isso, convertemos novamente de LTS P/ KG, o resultado*1,032

Private _aRecalVlrs:={}
                 //ORIGEM                ,DESTINO
aAdd(_aRecalVlrs,{"LEITE EM PO INTEGRAL 25 KG",'LEITE EM PO INTEGRAL',0})//Leite em pó Integral

aAdd(_aRecalVlrs,{"LEITE EM PO DESNATADO 25 KG",'LEITE EM PO DESNATADO',0})//Leite em pó Desnatado

//INICIAANDO VARIAVEIS StaticAS
_aSalvaCusMGCMS:={}
		
//==================================================
//Roda engine de dados de custo gerencial
//==================================================
//MV_PAR01 - Tipo Grupo
//MV_PAR02 - Grupo Custo
//MV_PAR05 - Data inicial
//MV_PAR06 - Data Final
// Ultimo parâmetro indica que e a primeira etapa de leitura da ZL6
Private _lMostraSoro:=.F.

If MV_PAR07 = 3//Gera Excel
   If cFilAnt = "10"
      _lMostraSoro := U_ITMsg("Custo operacional por planta?",'Atenção!', ,3,2,2)//ALERT
   EndIf  
EndIf

_nRegZL6 := U_MEST009E(MV_PAR01,MV_PAR02,MV_PAR05,MV_PAR06,1,_oSelf,@_lEnd)[1]
If _lLoop
   Return .F.
EndIf

DBSelectArea("ZL6T")

DBGoTop()
		
If ZL6T->(!Eof())
	//Executa relatorio 
	If MV_PAR07 = 1
		MEST009P()
	EndIf
		
	//Atualiza dados
	If MV_PAR07 = 2
		//VERIFICA PERMISSAO DE ACESSO PARA GRAVACAO
		_lRet :=  U_ITVACESS( 'ZZL' , 3 , 'ZZL_WCUSTO' , "S" )

		If !_lRet
			U_ITMsg( 'Usuario sem acesso à gravacao de custos gerenciais!', "ATENÇÃO" ,;
					 'Favor entrar em contato com o responsavel do Leite.', 3  )
	
			Return .F.
		EndIf
		_lGera1Pla:= .T.//Liga para calcular os dados de DEMONSTRATIVO DO ESTOQUE FINAL PLANILHA 03 Grupo (000006) OU (PLANILHA 02 PASTA 2 Grupos (000004/000005) ) ZL6T->ZL6_OBSERV == "E"
		//RODA GRAVACAO DE DADOS
		_lRet := MEST009D(_oSelf,_nRegZL6,@_lEnd)  

		//VERIFICA SE USUARIO PODE E QUER FAZER O FECHAMENTO
		If _lRet
			If U_ITVACESS( 'ZZL' , 3 , 'ZZL_FCUSTO' , "S" )
				If U_ITMsg("Gravar fechamento para o mês " + StrZero(MONTH(MV_PAR05),2) + " /" + AllTrim(Str(YEAR(MV_PAR05))) + " ?","Fechamento de custo",,3,2,2)// == 6
                    PutMv( "IT_ULMES", Strzero(Month(MV_PAR05),2) + AllTrim(Str(Year(MV_PAR05))) )
				EndIf				
			EndIf
		EndIf		
	EndIf
	
	//Gera Excel
	If MV_PAR07 = 3
	   _lMensagem:=MEST009Y(_oself,_nRegZL6,@_lEnd)
	EndIf
Else
	U_ITMsg("Nao foram encontradas regras de custo para os paramentros informados",'Atenção',"Verifique os paramentros e tente novamente",1)	
    Return .F.
EndIf
	
If Select("ZL6T") > 0 
	ZL6T->( DBCloseArea() )
EndIf

//abre novamente a tela inicial
_lLoop:=.T.	
If _lMensagem
   U_ITMsg("Planilha(s) "+AllTrim(MV_PAR12)+" Gerada(s)!!!",'Informação!',"Hora inicial: "+_cTimeIni+CRLF+"Hora final: "+TIME(),2)
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MEST009D
Autor-------------: Josue Danich Prestes
Data da Criacao---: 04/11/2015
Descricao---------: Gera dados de custos gerenciais
Parametros--------: _oself - Objeto da interface principal / _nRegZL6 - numero de registros lidos na ZL6  / _lEnd - Variavel de Cancelamento
Retorno-----------: .T. se processou com sucesso ou .F. se ocorreram erros ou cancelamento do processamento
===============================================================================================================================
*/
Static Function MEST009D(_oSelf,_nRegZL6,_lEnd)

Local _cFiltro 		:= ""
Local _culmes		:= ""
Local _nI			:= 1
Local _aze0			:= {}
Local _aze1			:= {}
Local _azeNew		:= {}
Local _nvalope		:= 0
Local _aprod		:= {}
Local _acustop		:= {}
Local _ns 			:= 0
Local _atotprod		:= {}
Local _ntotop		:= 0
Local _ntotprod 	:= 0
Local _no 			:= 0 , _Cus  , _np , _Pi , _Qba

//Define data inicial e final e pergunta se continua
MV_PAR05 := SToD(AllTrim(Str(year(MV_PAR05))) + StrZero((month(MV_PAR05)),2)+"01")

If month(MV_PAR05) < 12
	MV_PAR06 := SToD(AllTrim(Str(year(MV_PAR05))) + StrZero((month(MV_PAR05)+1),2)+"01") - 1
Else
	MV_PAR06 := SToD(AllTrim(Str((year(MV_PAR05)+1))) + "0101") - 1
EndIf

//Verifica se nao vai rodar período ja fechado pelo IT_ULMES
_culmes := SuperGetMV("IT_ULMES",.F.,"012001")

If	(SubStr(_culmes,3,4) >  AllTrim(Str(year(MV_PAR05)))) .Or. (SubStr(_culmes,3,4) =  AllTrim(Str(year(MV_PAR05))) .And.  SubStr(_culmes,1,2) >= StrZero(MONTH(MV_PAR05),2))
	U_ITMsg("Período selecionado já fechado! ( " + SubStr(_culmes,1,2) + "/" + SubStr(_culmes,3,4) + " ).","Fechamento","Reabra o fechamento para nova gravacao.",1)
	Return .F.
EndIf

If !U_ITMsg("At. Dados sera realizada para período de " + DToC(MV_PAR05) + " ate " + DToC(MV_PAR06) + ", continua?","Atualizacao Dados",,3,2,2)// <> 6
   Return .F.
EndIf

//Roda SubEngine que prepara arrays e valores de gravação
MEST009SE( _nRegZL6, _oself, @_aze0, @_aze1, @_nvalope, @_azeNew,@_lEnd)
If _lLoop
   Return .F.
EndIf

//unifica _aze0 e _aze1
While _nI <= Len(_aze1)
	aAdd(_aze0,_aze1[_nI])
	_nI++
EndDo

//elimina itens suprimidos e nao soma
_nI := 1

_aze1 := _aze0
_aze0 := {}

While _nI <= Len(_aze1)
	If (_aze1[_nI][13] != '4' .And. _aze1[_nI][13] != '5') .Or. _aze1[_nI][16] == '6'
		aAdd(_aze0,_aze1[_nI])
	EndIf
	_nI++
EndDo

//Algutina itens regra 2
_nI := 1

_aze1 := _aze0
_aze0 := {}

While _nI <= Len(_aze1)
	_np := aScan(_aze0,{|_vAux|_vAux[1]==_aze1[_nI][01] .And. _vAux[2]==_aze1[_nI][02]  .And. _vAux[4]==_aze1[_nI][04]  .And.  _vAux[8]==_aze1[_nI][08].and.  _vAux[17]==_aze1[_nI][14] }) 

	If !(_aze1[_nI][13] == '2') .And. _np > 0
		_aze0[_np][10]  +=  _aze1[_nI][10]
		_aze0[_np][11]  +=  _aze1[_nI][11]	
	Else	
		aAdd(_aze0,_aze1[_nI])
	EndIf
	_nI++
EndDo

_oself:SetRegua1( _nRegZL6 )
_oself:SetRegua2( _nRegZL6 )
_nI := 1 

_nRegZL6:=Len(_aze0)
_nContaZ:=0
_oself:SetRegua1( _nRegZL6 )
_oself:SetRegua2( _nRegZL6 )
_cTotRegZL6:=AllTrim(Str(_nRegZL6))

_cTeste:=" ATUALIZACAO: "+CRLF
_aTotais:={}
_nI:=1
For _nI := 1 To Len(_aze0)
	If .NOT. (AllTrim(_aze0[_nI][05]) == "PRODUTOS ACABADOS PRODUZIDOS") // _aze0[_nI][16] == '6' .And. _aze0[_nI][3] == "PRODUTOS ACABADOS" .And. 
		_cChave:=AllTrim(_aze0[_nI][01])+AllTrim(_aze0[_nI][03])+AllTrim(_aze0[_nI][09])
		If (nPos:=aScan(_aTotais,{ |C| C[1] == _cChave })) = 0
			aAdd(_aTotais, {_cChave,0,0,0} )
			nPos:=Len(_aTotais)
		EndIf
		If !(Len(_aze0[_nI]) >= 21 .And. ValType(_aze0[_nI][21]) = "N" .And. _aze0[_nI][21] <> 0)//--> <> "N" //soma tudo que não tiver a regra do ZL6T->ZL6_CUSPR = "S" e "A" e "B"
		   _aTotais[nPos,2]+=_aze0[_nI][11]      //CUSTO PRODUCAO
		EndIf
		If "EMBALAGENS" $ _aze0[_nI][05]
		   _aTotais[nPos,3]+=_aze0[_nI][11]  //CUSTO PRODUTO ABERTO
		EndIf
	EndIf
Next

For _nI := 1 To Len(_aze0)
	If _aze0[_nI][3] == "PRODUTOS ACABADOS" .And. .NOT. AllTrim(_aze0[_nI][05]) == "PRODUTOS ACABADOS PRODUZIDOS"//_aze0[_nI][16] == '6' .And. 
		If  Len(_aze0[_nI]) >= 21 .And. ValType(_aze0[_nI][21]) = "N" .And. _aze0[_nI][21] <> 0//--> <> "N"
			_cChave:=AllTrim(_aze0[_nI][01])+AllTrim(_aze0[_nI][03])+AllTrim(_aze0[_nI][09])
			If (nPos:=aScan(_aTotais,{ |C| C[1] == _cChave })) <> 0
				_np := aScan(_atotlei,{|_vAux|_vAux[1]==_aze0[_nI][08]})
				If _np > 0
					_ntotlei2 := _atotlei[_np][2]
				Else
					_ntotlei2 := 1
				EndIf
				If _aze0[_nI][2] == '000001' .Or. _aze0[_nI][2] == '000003'
					_ntotlei2 := _ntotlei
				EndIf

				_nCusmed := _aTotais[nPos,2] / _ntotlei2//CUSTO PRODUCAO
				_nCusAbe := _aTotais[nPos,3] / _ntotlei2//CUSTO PRODUTO ABERTO

				If _aze0[_nI][21]=2 .And. _nCusAbe = 0//ZE0_TPCUS+ZE0_GRPCT+ZE0_DSECT
				   _nCusAbe:=MEST2BuscaZE0(_aze0[_nI][2],_aze0[_nI][9],_aze0[_nI][7],_aze0[_nI])
				EndIf

				_nCusFor := _aTotais[nPos,4] / (_ntotlei2+_nCusAbe)//CUSTO PRODUTO FORMULADO

				If _aze0[_nI][21] = 1  .And. _nCusmed <> 0     // ZL6T->ZL6_CUSPR = "S" = 1 = _aze0[_nI][21]
				   _aze0[_nI][11] := _nCusmed * _aze0[_nI][10]// CUSTO PRODUCAO
				ElseIf _aze0[_nI][21] = 2 .And. _nCusAbe <> 0  // ZL6T->ZL6_CUSPR = "A" = 2 = _aze0[_nI][21]
				   _aze0[_nI][11] := _nCusAbe * _aze0[_nI][10]// CUSTO PRODUTO ABERTO
				ElseIf _aze0[_nI][21] = 3 .And. _nCusFor <> 0  // ZL6T->ZL6_CUSPR = "B" = 3 = _aze0[_nI][21]
					_aze0[_nI][11] := _nCusFor * _aze0[_nI][10]// CUSTO PRODUTO FORMULADO
				EndIf
			EndIf
		EndIf
	EndIf
Next

_cTeste:=""
_nI:=1
While _nI <= Len(_aze0)
	_nContaZ++
    If ValType(_oSelf) = "O" 
	   _oself:IncRegua1("1/4-Gravando dados: "+AllTrim(Str(_nContaZ,6))+" de "+_cTotRegZL6)
       ProcessMessages()
	EndIf
    
	_np := aScan(_atotlei,{|_vAux|_vAux[1]==_aze0[_nI][08]})
	If _np > 0
		_ntotlei2 := _atotlei[_np][2]
	Else
		_ntotlei2 := 1
	EndIf  
	If _aze0[_nI][2] == '000001' .Or. _aze0[_nI][2] == '000003'
		_ntotlei2 := _ntotlei
	EndIf

	_cFiltro :=  xFilial("ZE0") + SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4) + _aze0[_nI][8] + _aze0[_nI][2]
	_cFiltro +=  _aze0[_nI][4] + _aze0[_nI][6]
	
	If ZE0->( DBSeek( _cFiltro ) )
		//Achou registro so atualiza quantidade e valor
		RecLock("ZE0",.F.)
		ZE0->ZE0_QTDE	:= _aze0[_nI][10]
		ZE0->ZE0_VALOR	:= _aze0[_nI][11]
		ZE0->ZE0_VLRLT	:= _aze0[_nI][11] / _ntotlei2
		ZE0->ZE0_VDOLAR := _aze0[_nI][11] / (_ntotlei2 * _nTotdol)
		ZE0->ZE0_LITRAG := _ntotlei2
	Else
		//Nao achou registro cria um novo
		RecLock("ZE0",.T.)    
		ZE0->ZE0_FILIAL := 	_aze0[_nI][1]	
		ZE0->ZE0_TPCUS	:=	_aze0[_nI][2]
		ZE0->ZE0_DTPCT	:=	_aze0[_nI][3]
		ZE0->ZE0_EVCUS	:=	_aze0[_nI][4]
		ZE0->ZE0_DEVCT	:=	_aze0[_nI][5]
		ZE0->ZE0_SEVCT	:= 	_aze0[_nI][6]
		ZE0->ZE0_DSECT	:= 	_aze0[_nI][7]
		ZE0->ZE0_GRPCT	:= 	_aze0[_nI][8]
		ZE0->ZE0_DGRPCT	:= 	_aze0[_nI][9]
		ZE0->ZE0_QTDE	:= 	_aze0[_nI][10]
		ZE0->ZE0_VALOR	:= 	_aze0[_nI][11]
		ZE0->ZE0_DATARQ	:= 	_aze0[_nI][12]
		ZE0->ZE0_VLRLT	:=  _aze0[_nI][11] / _ntotlei2
		ZE0->ZE0_VDOLAR :=  _aze0[_nI][11] / (_ntotlei2 * _nTotdol)
		ZE0->ZE0_LITRAG := _ntotlei2
	EndIf
	
	//Prepara array de total de custo e qtde de produção por grupo
	_ns:=0
	If ZE0->ZE0_TPCUS == '000002' .And. AllTrim(_aze0[_nI][16]) != "6" .And. AllTrim(_aze0[_nI][16]) != "1"
		_ns := aScan( _acustop,{|_vAux | _vAux[1] == AllTrim(ZE0->ZE0_GRPCT)})
		If _ns > 0
			_acustop[_ns][2] += ZE0->ZE0_VALOR
		Else
		    _cChave1:=xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)
		    _cChave2:=AllTrim(_aze0[_nI][01])+AllTrim(_aze0[_nI][03])+AllTrim(_aze0[_nI][09])

			aAdd(_acustop,{ AllTrim(ZE0->ZE0_GRPCT),;//01
			                        ZE0->ZE0_VALOR ,;//02
			                        	  _cChave1,; //03	
			                              _cChave2 ,;//04 
			                              0        })//05 nDev 
		EndIf
	ElseIf ZE0->ZE0_TPCUS == '000002' .And. AllTrim(_aze0[_nI][16]) == "6" 
		_ns := aScan( _atotprod,{|_vAux | _vAux[1] == AllTrim(ZE0->ZE0_GRPCT)})
		If _ns > 0
			_atotprod[_ns][2] += ZE0->ZE0_QTDE
		Else
			aAdd(_atotprod,{ AllTrim(ZE0->ZE0_GRPCT), ZE0->ZE0_QTDE })
		EndIf
		_ntotprod += ZE0->ZE0_QTDE
	ElseIf ZE0->ZE0_TPCUS == '000001' .Or. ZE0->ZE0_TPCUS == '000003'
		_ntotop += ZE0->ZE0_VALOR
	EndIf
			
	ZE0->(MSUnLock())
	
	//Adiciona registros finais de produto acabado produzido para cada produto
	If _aze0[_nI][16] == '6'
		//Prepara subtotal do grupo
		_nsubtot5		:= 0 
		_no := _nI //guarda posição do aray
                     
		For _nI := 1 To Len(_aze0)  
	 		If (AllTrim(_aze0[_nI][01])+AllTrim(_aze0[_nI][03])+AllTrim(_aze0[_nI][09]) == ;
	    		AllTrim(_aze0[_no][01])+AllTrim(_aze0[_no][03])+AllTrim(_aze0[_no][09])) .And. AllTrim(_aze0[_nI][5]) != "PRODUTOS ACABADOS PRODUZIDOS" 
	            _cTeste+=";"+ARRTOKSTR(_aze0[_nI],";")+CRLF
	            _cTeste+=TRANSFORM(_aze0[_nI][11], "@E 999999999.99" )+CRLF
				_nsubtot5 	+=	_aze0[_nI][11]
	            _cTeste+=CRLF
	  		EndIf
		Next
	
		_nI := _no
	    
	    DBSelectArea("ZL6")
		_cproduto:= Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_CODPRO")

	    _nVlrIcm :=_nVIcmEst:=_nVIcmInt:=_nVIcmTrs:=_nDifAlq:=0//Variaveis antigas
        _nICMSEst:=_nICMSInt:=_nICMSTrs:=0//Variaveis novas valores preco medio
        nDespEst := 0//Variaveis novas para calcular o percentual
        nDespInt := 0//Variaveis novas para calcular o percentual
        nDespTrs := 0//Variaveis novas para calcular o percentual
        _cChave  :=xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            "

        MEST9ICMS("CARGA_VARIAVEIS_ICMS",_cChave)

	    _cSegUni := Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_TUNID")
        _cEstAnt := Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_ESTANT")
        _cGrpCus := Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_GRPCUS")
        _cFilis  := Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_FILIS")
        _cLocais := Posicione("ZL6",8,xFilial("ZL6")+_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_LOCAL")

		_aval 		:= MEST009SB9(AllTrim(_cproduto),  _cSegUni,_cEstAnt,_cGrpCus)//valores de estoque anterior
		_aven 		:= MEST009SD1(AllTrim(_cproduto),2,_cSegUni)//valores de entradas em transferência
		_avdv 		:= MEST009SD1(AllTrim(_cproduto),1,_cSegUni)//valores de entradas em devolução
		_aicst 		:= MEST009IST(AllTrim(_cproduto))           //valores icms st
		_aExp 		:= MEST009EXP(AllTrim(_cproduto),  _cSegUni,_cLocais)//Quantidade expedida
		_aFret		:= MEST009FRT(AllTrim(_cproduto),_aExp[1][1])           //Valor Frete
		_nDev 		:= (_nsubtot5 + _aval[1][2]) / (_aval[1][1] + _ntotlei2)  //Valor real de devolução

         _cTeste+="_nDev(;"+TRANSFORM(_nsubtot5, "@E 999999999.99" )+"; + ;"+TRANSFORM(_aval[1][2], "@E 999999999.99" )+";) / (;"+TRANSFORM(_aval[1][1], "@E 999999999.99" )+"; + ;"+TRANSFORM(_ntotlei2, "@E 999999999.99" )+";)"+CRLF

		_nExp 		:= ((_aExp[1][1] ) * ( _nDev ))             //Valor real de expedição
		_nSldAtu	:= MEST9BscSB2(_cproduto)

        If _nICMSEst > 0 .And. nDespEst > 0
           _nVIcmEst:=(_nVIcmEst*_aExp[1][2])
        EndIf
        If _nICMSInt > 0 .And. nDespInt > 0
           _nVIcmInt:=(_nVIcmInt*_aExp[1][3])
        EndIf
        If _nICMSTrs > 0 .And. nDespTrs > 0
           _nVIcmTrs:=(_nVIcmTrs*_aExp[1][4])
        EndIf

		MEST009GRD(_aze0, _nI,_aval[1][2]			, _aval[1][1]					, "999999", "9999", "ESTOQUE ANTERIOR")
		MEST009GRD(_aze0, _nI,_avdv[1][1] * _nDev	, _avdv[1][1]					, "999998", "9998", "ENTRADAS DEVOLUCAO")
		MEST009GRD(_aze0, _nI,_aven[1][2]			, _aven[1][1]					, "999997", "9997", "ENTRADAS TRANSFERENCIA")
		MEST009GRD(_aze0, _nI,_nExp					, _aExp[1][1]					, "999996", "9996", "EXPEDIDO")
		MEST009GRD(_aze0, _nI,_aFret[1][1]			, _aExp[1][1]					, "999995", "9995", "FRETE")
		MEST009GRD(_aze0, _nI,_nVIcmEst  			, _aExp[1][1]					, "999994", "9994E", "ICMS Estadual")
		MEST009GRD(_aze0, _nI,_nVIcmInt  			, _aExp[1][1]					, "999994", "9994I", "ICMS InterEstadual")
		MEST009GRD(_aze0, _nI,_nVIcmTrs  			, _aExp[1][1]					, "999994", "9994T", "ICMS Transferencia")
		MEST009GRD(_aze0, _nI,_aicst[1][1]			, _aExp[1][1]					, "999993", "9993", "ICMS Substituicao Tributaria")
		MEST009GRD(_aze0, _nI,_nDifAlq				, _aExp[1][1]					, "999993", "9992", "ICMS Diferencial Aliquota")
		MEST009GRD(_aze0, _nI,_nSldAtu * _nDev		, _nSldAtu 						, "999992", "9991", "ESTOQUE ATUAL")
	EndIf
	_nI++
EndDo

_cTeste:=StrTran(_cTeste,".",",")
_cFileNome:=_cdir+"MEST009_GRV_ESTOQUE_ATUAL_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".CSV"
MemoWrite(_cFileNome,_cTeste)

// Recalcula o TOTAL PRODUTOS ACABADOS para ficar igual o da geração do Excel - AWF
_nRegZL6:=Len(_acustop)
_nContaZ:=0
_oself:SetRegua2( _nRegZL6 )
_cTotRegZL6:=AllTrim(Str(_nRegZL6))

For _Cus := 1 To Len(_acustop)
	If ValType(_oSelf) = "O"
		_oself:IncRegua2("2/4-Gravando dados: "+AllTrim(Str(_nContaZ,6))+" de "+_cTotRegZL6)
		ProcessMessages()
	EndIf
	
	_cChave1:=_acustop[_Cus][3]
	_cChave2:=_acustop[_Cus][4]
	
	_np := aScan(_atotlei,{|_vAux|_vAux[1]==_acustop[_Cus][1]})
	If _np > 0
		_ntotlei2 := _atotlei[_np][2]
	Else
		_ntotlei2 := 1
	EndIf
	_nsubtot5:=0
	For _nI := 1 To Len(_aze0)
		If (AllTrim(_aze0[_nI][01])+AllTrim(_aze0[_nI][03])+AllTrim(_aze0[_nI][09]) == _cChave2 ) .And. AllTrim(_aze0[_nI][5]) != "PRODUTOS ACABADOS PRODUZIDOS"
			_nsubtot5 	+=	_aze0[_nI][11]
		EndIf
	Next
	
	_cproduto:= Posicione("ZL6",8,_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_CODPRO")
	_nVlrIcm :=_nVIcmEst:=_nVIcmInt:=_nVIcmTrs:=_nDifAlq:=0//Variaveis antigas
	_nICMSEst:=_nICMSInt:=_nICMSTrs:=0//Variaveis novas valores preco medio
	nDespEst := 0//Variaveis novas para calcular o percentual
	nDespInt := 0//Variaveis novas para calcular o percentual
	nDespTrs := 0//Variaveis novas para calcular o percentual
	_cChave  :=_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            "
	
	MEST9ICMS("CARGA_VARIAVEIS_ICMS",_cChave)
	
	_cSegUni := Posicione("ZL6",8,_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_TUNID")
	_cEstAnt := Posicione("ZL6",8,_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_ESTANT")
	_cGrpCus := Posicione("ZL6",8,_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_GRPCUS")
	_cLocais := Posicione("ZL6",8,_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_LOCAL")
	
	_aval 	 := MEST009SB9(AllTrim(_cproduto),_cSegUni,_cEstAnt,_cGrpCus)  //valores de estoque anterior
	_aicst 	 := MEST009IST(AllTrim(_cproduto))           //valores icms st
	_aExp 	 := MEST009EXP(AllTrim(_cproduto),_cSegUni,_cLocais)  //Quantidade expedida
	_aFret	 := MEST009FRT(AllTrim(_cproduto),_aExp[1][1])           //Valor Frete
	
	If _nICMSEst > 0 .And. nDespEst > 0
		_nVIcmEst:=(_nVIcmEst*_aExp[1][2])
	EndIf
	If _nICMSInt > 0 .And. nDespInt > 0
		_nVIcmInt:=(_nVIcmInt*_aExp[1][3])
	EndIf
	If _nICMSTrs > 0 .And. nDespTrs > 0
		_nVIcmTrs:=(_nVIcmTrs*_aExp[1][4])
	EndIf
	_nVlrIcm := _nVIcmEst + _nVIcmInt + _nVIcmTrs
	
	_nDev 	 := (_nsubtot5 + _aval[1][2])/(_aval[1][1] + _ntotlei2)  //Valor real de devolução
	_nExp 	 := ((_aExp[1][1] ) * ( _nDev ))    //Valor real de expedição
	
	_nCustoGeral := _nExp +  _aFret[1][1] + _aicst[1][1]+  _nVlrIcm + _nDifAlq//Recalcula o TOTAL PRODUTOS ACABADOS para ficar igual o da geração do Excel
	
	_acustop[_Cus][2] := If(_nCustoGeral>0,_nCustoGeral,_acustop[_Cus][2])
	_acustop[_Cus][5] := _nDev
Next

// Grava dados de produtos para ZE1

//monta array de produtos acabados com custo de produção
_nI := 1

While _nI <= Len(_aze0)
	If AllTrim(_aze0[_nI][16]) == "6" 
		_aRet    := MEST009PMMTFQF(_aze0[_nI][15])//Procura preço mínimo, preço máximo, total de faturamento e quantidade faturada
		_nPrcmin := _aRet[1]
		_nPrcmax := _aRet[2]
		_nfatura := _aRet[3]
		_nqtdfat := _aRet[4]
		
		_nPosCus := aScan( _acustop,{|_vAux | _vAux[1] == AllTrim(_aze0[_nI][8]) })
		_ncuspro := _aze0[_nI][10] * _acustop[ _nPosCus ][2]
 		_ncuspro := _ncuspro /(_atotprod[ aScan( _atotprod,{|_vAux | _vAux[1] == AllTrim(_aze0[_nI][8])}) ][2])
		_ncusop  := _aze0[_nI][10] * (_ntotop / _ntotlei)//_aze0[_nI][10] * (_ntotop / _ntotprod)
		_nDev    := _acustop[_nPosCus][5]
	
		aAdd(_aprod, { _aze0[_nI][15],;   	    //01 Produto
						 _nPrcmin,; 			//02 Preco Minimo *
						 _nPrcmax,; 			//03 Preco Maximo  *
						 _ncuspro,; 			//04 Custo produção
						 _nfatura,; 			//05 Faturado
						 _nqtdfat,; 			//06 Qtde Faturada *
						 _aze0[_nI][10],; 		//07 Qtde Produzida  *******
						 _aze0[_nI][12],;		//08 Competencia
						 _ncusop,;				//09 Custo operacional
						  0,;					//10 Embalagens
						  0,;					//11 Frete
						  0,;					//12 Insumos
						  0,;					//13 Outros
						  0,;					//14 Leite mp
						  _aze0[_nI][9],;		//15 Descriçao do grupo do custo
						  (_atotprod[aScan( _atotprod,{|_vAux | _vAux[1] == AllTrim(_aze0[_nI][8])})][2]),;//16 Total produzido do grupo
						  _aze0[_nI][19] ,;     //17 Centros de custos
						  _aze0[_nI][08] ,;     //18 Código do grupo de custo //AWF 03/05/17
						  _aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40) ,;//19 CHAVE para dar seek no ZL6//AWF 11/09/17
						  _nDev               })//20 Valor acumulado + devolucao /- transferencia do grupo//AWF 11/09/17
        
	EndIf
	_nI++
EndDo

//atualiza custos proporcionais no array de produtos
For _nI := 1 To Len(_aze0)
	If AllTrim(_aze0[_nI][02]) == "000002"  // tipo de custo de produto acabado
		//Embalagens
		If AllTrim(_aze0[_nI][16]) == "2"
			For _np := 1 To Len(_aprod)
				If AllTrim(_aprod[_np][15]) == AllTrim(_aze0[_nI][09])
					_aprod[_np][10] += ( _aprod[_np][07] / _aprod[_np][16]) *  _aze0[_nI][11]
				EndIf
			Next
		EndIf
		
		//Frete
		If AllTrim(_aze0[_nI][16]) == "3"
			For _np := 1 To Len(_aprod)
				If AllTrim(_aprod[_np][15]) == AllTrim(_aze0[_nI][09])
					_aprod[_np][11] += ( _aprod[_np][07] /_aprod[_np][16] ) *  _aze0[_nI][11]
				EndIf
			Next
		EndIf
		
		//Insumos
		If AllTrim(_aze0[_nI][16]) == "4"
			For _np := 1 To Len(_aprod)
				If AllTrim(_aprod[_np][15]) == AllTrim(_aze0[_nI][09])
					_aprod[_np][12] += ( _aprod[_np][07] / _aprod[_np][16]) *  _aze0[_nI][11]
				EndIf
			Next
		EndIf
		
		//Outros
		If AllTrim(_aze0[_nI][16]) == "5"
			For _np := 1 To Len(_aprod)
				If AllTrim(_aprod[_np][15]) == AllTrim(_aze0[_nI][09])
					_aprod[_np][13] += ( _aprod[_np][07] / _aprod[_np][16]) *  _aze0[_nI][11]
				EndIf
			Next
		EndIf
		
		//Leite-MP
		If AllTrim(_aze0[_nI][16]) == "7"
			For _np := 1 To Len(_aprod)
				If AllTrim(_aprod[_np][15]) == AllTrim(_aze0[_nI][09])
					_aprod[_np][14] += ( _aprod[_np][07] / _aprod[_np][16]) *  _aze0[_nI][11]
				EndIf
			Next
		EndIf
	EndIf
Next

_aQuebraProd:={}

_cQuery1:= " SELECT " 
_cQuery1+= " SUM(SD3.D3_QUANT) AS TOT " 
_cQuery1+= " FROM " + RetSqlName("SD3") + " SD3 "
_cQuery1+= " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
_cQuery1+= " AND   SD3.D3_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery1+= " AND   SD3.D3_CF IN ('PR0') "
_cQuery1+= " AND   SD3.D3_ESTORNO <> 'S' "
_cQuery1+= " AND   SD3.D_E_L_E_T_ = ' '	"

_nRegZL6:=Len(_aprod)
_nContaZ:=0
_oself:SetRegua1( _nRegZL6 )
_cTotRegZL6:=AllTrim(Str(_nRegZL6))

For _nI := 1 To Len(_aprod)
	_nContaZ++
    If ValType(_oSelf) = "O" 
	   _oself:IncRegua1("3/4-Gravando dados: "+AllTrim(Str(_nContaZ,6))+" de "+_cTotRegZL6)
       ProcessMessages()
	EndIf

	_aItem := StrTokArr(AllTrim(_aprod[_nI][01]), ';')
    nTotQtdeProd:=0
	If Len(_aItem) > 1 .And. ValType(_aItem) = "A"
       For _Pi := 1 To Len(_aItem)   
	       _cAlias := GetNextAlias()
	       _cQuery2:= " AND   SD3.D3_COD = '" + _aItem[_Pi] + "'"
	       If !Empty(_aprod[_nI][17])
	          _cQuery2+= " AND   SD3.D3_CC IN " +  FormatIn(AllTrim(_aprod[_nI][17]),";") 
	       EndIf   
           MPSysOpenQuery( (_cquery1+_cquery2) , _cAlias ) 
           nQtdeProd:=(_cAlias)->TOT
           If nQtdeProd # 0
		      _aRet := MEST009PMMTFQF(_aItem[_Pi])//Procura preço mínimo, preço máximo, total de faturamento e quantidade faturada
              nTotQtdeProd+=nQtdeProd//Soma só para conferir no debug se bate com o _aprod[_nI][07]
              aAdd(_aQuebraProd,{AllTrim(_aprod[_nI][01]),;//01-Grupo dos itens
                                              _aItem[_Pi],;//02-Item
                                                nQtdeProd,;//03-Qtde do item
                                          _aprod[_nI][07],;//04-total dos itens
                                                    _aRet})//05-Preço mínimo, Preço máximo, Total de Faturamento e Quantidade Faturada
           EndIf                                               
       Next
	Else
       aAdd(_aQuebraProd,{AllTrim(_aprod[_nI][01]), _aItem[1], _aprod[_nI][07], _aprod[_nI][07], {0,0,0,0} })
	EndIf
Next	
		
//grava ZE1
_nRegZL6:=Len(_aQuebraProd)
_nContaZ:=0
_oself:SetRegua2( _nRegZL6 )
_cTotRegZL6:=AllTrim(Str(_nRegZL6))

DBSelectArea("ZE1")
ZE1->( DBSetOrder(1) )

For _Qba := 1 To Len(_aQuebraProd)
    If ValType(_oSelf) = "O" 
	   _oself:IncRegua2("4/4-Gravando dados: "+AllTrim(Str(_nContaZ,6))+" de "+_cTotRegZL6)
       ProcessMessages()
	EndIf

   _nFator  := (_aQuebraProd[_Qba,3]/_aQuebraProd[_Qba,4])
   _nFator  := If(_nFator<=0,1,_nFator)
   _aRet    := _aQuebraProd[_Qba,5]
   _nPrcmin := _aRet[1]//SD2T->PRCMIN
   _nPrcmax := _aRet[2]//SD2T->PRCMAX
   _nfatura := _aRet[3]//SD2T->FATUR
   _nqtdfat := _aRet[4]//SD2T->QTDE

   For _nI := 1 To Len(_aprod)
      If !(AllTrim(_aprod[_nI][01]) == _aQuebraProd[_Qba,1])
         Loop
      EndIf
      _cSeek:=_aprod[_nI][19]//_aze0[_nI][8]+PadR(_aze0[_nI][3],60)+PadR(_aze0[_nI][9],40)
	  _nVlrIcm :=_nVIcmEst:=_nVIcmInt:=_nVIcmTrs:=_nDifAlq:=0//Variaveis antigas
      _nICMSEst:=_nICMSInt:=_nICMSTrs:=0//Variaveis novas valores preco medio
	  nDespEst := 0//Variaveis novas para calcular o percentual
	  nDespInt := 0//Variaveis novas para calcular o percentual
	  nDespTrs := 0//Variaveis novas para calcular o percentual
	  _cChave  :=_cChave1+"PRODUTOS ACABADOS PRODUZIDOS            "
	
	  MEST9ICMS("CARGA_VARIAVEIS_ICMS",_cChave)

      _cSegUni := Posicione("ZL6",8,xFilial("ZL6")+_cSeek+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_TUNID")
      _cEstAnt := Posicione("ZL6",8,xFilial("ZL6")+_cSeek+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_ESTANT")
      _cGrpCus := Posicione("ZL6",8,xFilial("ZL6")+_cSeek+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_GRPCUS")
      _cFilis  := Posicione("ZL6",8,xFilial("ZL6")+_cSeek+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_FILIS")
      _cLocais := Posicione("ZL6",8,xFilial("ZL6")+_cSeek+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_LOCAL")

	  _cproduto:= AllTrim(_aprod[_nI][01])

	  _aTotItem:= MEST009SB9(AllTrim(_cproduto),_cSegUni,_cEstAnt,_cGrpCus,.T.)	//valores de estoque anterior
	  If (_nPos:=aScan(_aTotItem,{|I| I[1] == SubStr(AllTrim(_aQuebraProd[_Qba,2]),1,11) } )) # 0
	      _nEstoqueAnterior:= _aTotItem[_nPos,2]
      Else
          _nEstoqueAnterior:= 0
	  EndIf    
    
	_aven 		:= MEST009SD1(AllTrim(_cproduto),2,_cSegUni)  	//valores de entradas em transferência
	_avdv 		:= MEST009SD1(AllTrim(_cproduto),1,_cSegUni)  	//valores de entradas em devolução
	_aicst 		:= MEST009IST(AllTrim(_cproduto))  		        //valores icms st
	_aExp 		:= MEST009EXP(AllTrim(_cproduto),_cSegUni,_cLocais)  	//Quantidade expedida
	_aFret		:= MEST009FRT(AllTrim(_cproduto),_aExp[1][1])          	//Valor Frete
	_nDev 		:= _aprod[_nI][20]//(_aprod[_nI][04] + _aval[1][2]) / (_aval[1][1] + _aprod[_nI][16])  //Valor real de devolução
	_aTotItem	:= MEST9BscSB2(_cproduto,.T.)

	If _nICMSEst > 0 .And. nDespEst > 0
		_nVIcmEst:=(_nVIcmEst*_aExp[1][2])
	EndIf
	If _nICMSInt > 0 .And. nDespInt > 0
		_nVIcmInt:=(_nVIcmInt*_aExp[1][3])
	EndIf
	If _nICMSTrs > 0 .And. nDespTrs > 0
		_nVIcmTrs:=(_nVIcmTrs*_aExp[1][4])
	EndIf
	_nVlrIcm := _nVIcmEst + _nVIcmInt + _nVIcmTrs

	If (_nPos:=aScan(_aTotItem,{|I| I[1] == SubStr(AllTrim(_aQuebraProd[_Qba,2]),1,11) } )) # 0
	    _nSaldoAtual:= _aTotItem[_nPos,2]
	    _nValorAtual:= (_nSaldoAtual*_nDev) //* _nFator
    Else
        _nSaldoAtual:= 0
	    _nValorAtual:= 0
	EndIf

	_cFiltro :=  xFilial("ZE1") + SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4) + Space(4) + SubStr(AllTrim(_aQuebraProd[_Qba,2]),1,11)   //_aprod[_nI][01]
		
	If ZE1->( DBSeek( _cFiltro ) )
		//Achou registro so atualiza quantidade e valor
		RecLock("ZE1",.F.)
		ZE1->ZE1_PRCMIN		:= If(_nPrcmin#0,_nPrcmin,_aprod[_nI][02])
		ZE1->ZE1_PRCMAX		:= If(_nPrcmax#0,_nPrcmax,_aprod[_nI][03])
		ZE1->ZE1_CUSTOP		:= (_aprod[_nI][04]*_nFator)
		ZE1->ZE1_FATURA		:= If(_nFatura#0,_nFatura,_aprod[_nI][05])
		ZE1->ZE1_QTDFAT		:= If(_nqtdfat#0,_nqtdfat,_aprod[_nI][06])
		ZE1->ZE1_QTDPRO		:= _aQuebraProd[_Qba,3] //_aprod[_nI][07]
		ZE1->ZE1_CUSTOO		:= (_aprod[_nI][09]*_nFator)
		ZE1->ZE1_CUSTOE		:= (_aprod[_nI][10]*_nFator)
		ZE1->ZE1_CUSTOF		:= (_aFret[1][1]*_nFator)
		ZE1->ZE1_CUSTOI		:= (_aprod[_nI][12]*_nFator)
		ZE1->ZE1_CUSTOU		:= (_aprod[_nI][13]*_nFator)
		ZE1->ZE1_CUSTOL		:= (_aprod[_nI][14]*_nFator)
		ZE1->ZE1_ESTA		:= _nEstoqueAnterior//(_aval[1][2]*_nFator)
		ZE1->ZE1_ENTRA		:= (_aven[1][2]*_nFator)
		ZE1->ZE1_ENDEV		:= (_avdv[1][2]*_nFator)
		ZE1->ZE1_ICMS		:= (_nVlrIcm*_nFator)//_aicms[1][1]
		ZE1->ZE1_ICST		:= (_aicst[1][1] *_nFator)
		ZE1->ZE1_EXPE		:= (_aExp[1][1] *_nFator)
		ZE1->ZE1_DIFALQ		:= (_nDifAlq*_nFator)
		ZE1->ZE1_ESTATU		:= _nSaldoAtual//(_nSldAtu*_nFator)
		ZE1->ZE1_VESTAT		:= _nValorAtual
	Else
		//Nao achou registro cria um novo
		RecLock("ZE1",.T.)    
		ZE1->ZE1_FILIAL		:= xFilial("SD2")	
		ZE1->ZE1_PRODUT		:= _aQuebraProd[_Qba,2]  //SubStr(AllTrim(_aprod[_nI][01]),1,11)	
		ZE1->ZE1_PRCMIN		:= If(_nPrcmin#0,_nPrcmin,_aprod[_nI][02])
		ZE1->ZE1_PRCMAX		:= If(_nPrcmax#0,_nPrcmax,_aprod[_nI][03])
		ZE1->ZE1_CUSTOP		:= (_aprod[_nI][04]*_nFator)
		ZE1->ZE1_FATURA		:= If(_nFatura#0,_nFatura,_aprod[_nI][05])
		ZE1->ZE1_QTDFAT		:= If(_nqtdfat#0,_nqtdfat,_aprod[_nI][06])
		ZE1->ZE1_QTDPRO		:= _aQuebraProd[_Qba,3] //_aprod[_nI][07]
		ZE1->ZE1_CUSTOO		:= (_aprod[_nI][09]*_nFator)
	   	ZE1->ZE1_COMP		:= _aprod[_nI][08]
	   	ZE1->ZE1_CUSTOE		:= (_aprod[_nI][10]*_nFator)
		ZE1->ZE1_CUSTOF		:= (_aFret[1][1]*_nFator)
		ZE1->ZE1_CUSTOI		:= (_aprod[_nI][12]*_nFator)
		ZE1->ZE1_CUSTOU		:= (_aprod[_nI][13]*_nFator)
		ZE1->ZE1_CUSTOL		:= (_aprod[_nI][14]*_nFator)
		ZE1->ZE1_ESTA		:= _nEstoqueAnterior//(_aval[1][2]*_nFator)
		ZE1->ZE1_ENTRA		:= (_aven[1][2]*_nFator)
		ZE1->ZE1_ENDEV		:= (_avdv[1][2]*_nFator)
		ZE1->ZE1_ICMS		:= (_nVlrIcm*_nFator)//_aicms[1][1]
		ZE1->ZE1_ICST		:= (_aicst[1][1]*_nFator)
		ZE1->ZE1_EXPE		:= (_aExp[1][1]*_nFator)
		ZE1->ZE1_DIFALQ		:= (_nDifAlq*_nFator)
		ZE1->ZE1_ESTATU		:= _nSaldoAtual//(_nSldAtu*_nFator)
		ZE1->ZE1_VESTAT		:= _nValorAtual
	EndIf
	
	_cCodGrupo       	:= Posicione("SB1",1,xFilial("SB1")+ZE1->ZE1_PRODUT,"B1_GRUPO")
	ZE1->ZE1_GRUPO		:= Posicione("SBM",1,xFilial("SBM")+_cCodGrupo     ,"BM_DESC")//Descrição do grupo do produto   
	If ZE1->(FIELDPOS("ZE1_GRPCT")) # 0
	   ZE1->ZE1_GRPCT   := _aprod[_nI][18]//Código do grupo do custo    ZE0->ZE0_GRPCT :=_aze0[_nI][8]
	   ZE1->ZE1_DRGPCT  := _aprod[_nI][15]//Descriçao do grupo do custo ZE0->ZE0_DGRPCT:=_aze0[_nI][9]
	EndIf
	
	ZE1->(MSUnLock())       
   Next	
Next

U_ITMsg("Dados atualizados com sucesso para período " + SubStr(DToS(MV_PAR05),5,2) + "/" +  SubStr(DToS(MV_PAR05),1,4) + ".", "Atualizacao Dados",,2) 

Return .T.

/*
===============================================================================================================================
Programa----------: MEST009P
Autor-------------: Josue Danich Prestes
Data da Criacao---: 31/10/2014
Descricao---------: Relatorio de custos gerenciais
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
Static Function MEST009P()

Private oReport
lPrim 	:= .F.

oReport := MEST009RP()
oReport:PrintDialog()

Return

/*
===============================================================================================================================
Programa----------: MEST009RP
Autor-------------: Josue Danich Prestes
Data da Criacao---: 31/10/2014
Descricao---------: Gera planilha de custos
Parametros--------:
Retorno-----------: oReport - objeto de impressao
===============================================================================================================================
*/
Static Function MEST009RP()

Local oSection1
Local oBreak1

If MV_PAR08 == 1
	cDescTp := "Sintetico"
Else
	cDescTp := "Analitico"
EndIf

oReport:= TReport():New("Planilha de Custos (MEST009)","Planilha de Custos - "+cDescTp,"MEST009",{|oReport| MEST009I(oReport) },"Impressao da Planilha de Custos gerado atraves da rotina MEST009")
oReport:SetLandScape()
oReport:SetTotalInLine(.F.)
oReport:ParamReadOnly(.T.)

//Definicao das secoes do relatorio |
oSection1 := TRSection():New(oReport, "Custos",{"ZL6","SD1","SD3","SE5","SE2"})

//Definicao das celulas para impressao |
DBSelectArea("SX3")
DBSetOrder(2)

SX3->( DBSeek("ZL6_DTPCUS") )
TRCell():New(oSection1,"ZL6_DTPCUS","ZL6",X3TITULO(),,TamSX3("ZL6_DTPCUS")[1]+2)
SX3->( DBSeek("ZL6_DGRCUS") )
TRCell():New(oSection1,"ZL6_DGRCUS","ZL6",X3TITULO(),,TamSX3("ZL6_DGRCUS")[1]+2)
SX3->( DBSeek("ZL6_DESEVE") )
TRCell():New(oSection1,"ZL6_DESEVE","ZL6",X3TITULO(),,TamSX3("ZL6_DESEVE")[1]+2)
SX3->( DBSeek("ZL6_DSUBEV") )
TRCell():New(oSection1,"ZL6_DSUBEV","ZL6",X3TITULO(),,TamSX3("ZL6_DSUBEV")[1]+2)

If MV_PAR08 == 2	//Analitico
	SX3->( DBSeek("D1_COD") )
	TRCell():New(oSection1,"PRODCOD","ZL6",X3TITULO(),,TamSX3("D1_COD")[1]+1)
	SX3->( DBSeek("D1_I_DESC") )
	TRCell():New(oSection1,"PRODDESC","ZL6",X3TITULO(),,TamSX3("D1_I_DESC")[1]+1)

	TRCell():New(oSection1,"CODFORN","ZL6","Cod Forn/Clente",,10)

	TRCell():New(oSection1,"DESFORN","ZL6","Nome",,100)

	SX3->( DBSeek("D1_CF") )
	TRCell():New(oSection1,"CFOP","ZL6",X3TITULO(),,TamSX3("D1_CF")[1]+1)
EndIf

SX3->( DBSeek("D1_QUANT") ) 
TRCell():New(oSection1,"QUANT","SD1",X3TITULO(),,TamSX3("D1_QUANT")[1]+2)
SX3->( DBSeek("D1_TOTAL") )
TRCell():New(oSection1,"VALOR","SD1",X3TITULO(),,TamSX3("D1_TOTAL")[1]+2)

If MV_PAR08 == 2	//Analitico
	SX3->( DBSeek("D1_DOC") )
	TRCell():New(oSection1,"DOC","SD1",X3TITULO(),,TamSX3("D1_DOC")[1]+2)
	SX3->( DBSeek("D1_CC") )
	TRCell():New(oSection1,"CCUSTO","SD1",X3TITULO(),,TamSX3("D1_CC")[1]+2)
	SX3->( DBSeek("E5_NATUREZ") )
	TRCell():New(oSection1,"NATUREZA","SD1",X3TITULO(),,TamSX3("E5_NATUREZ")[1]+2)
	SX3->( DBSeek("E5_DATA") )
	TRCell():New(oSection1,"DATA","SE5",X3TITULO(),,TamSX3("E5_DATA")[1]+2)
	SX3->( DBSeek("D1_EMISSAO") )
	TRCell():New(oSection1,"EMISSAO","SD1",X3TITULO(),,TamSX3("D1_EMISSAO")[1]+2)
	SX3->( DBSeek("D1_DTDIGIT") )
	TRCell():New(oSection1,"DTDIGIT","SD1",X3TITULO(),,TamSX3("D1_DTDIGIT")[1]+2)
	TRCell():New(oSection1,"TES","SD1","TES",,TamSX3("D1_TES")[1]+2)
	SX3->( DBSeek("D1_NUMSEQ") )
	TRCell():New(oSection1,"NUMSEQ","SD1",X3TITULO(),,TamSX3("D1_NUMSEQ")[1]+2)
	TRCell():New(oSection1,"USUARIO","SD1","Usuario",,30)
	SX3->( DBSeek("RD_MAT") )
	TRCell():New(oSection1,"MAT","SRC",X3TITULO(),,TamSX3("RD_MAT")[1]+2)
	SX3->( DBSeek("RD_PD") )
	TRCell():New(oSection1,"PD","SRC",X3TITULO(),,TamSX3("RD_PD")[1]+2)
	SX3->( DBSeek("RD_TIPO1") )
	TRCell():New(oSection1,"TIPO1","SRC",X3TITULO(),,TamSX3("RD_TIPO1")[1]+2)
	SX3->( DBSeek("E2_FILIAL") )
	TRCell():New(oSection1,"FILIAL","SE2",X3TITULO(),,TamSX3("E2_FILIAL")[1]+2)
	SX3->( DBSeek("D3_I_OBS") )
	TRCell():New(oSection1,"OBS","SD3",X3TITULO(),,TamSX3("D3_I_OBS")[1]+2)
		
	oBreak1 := TRBreak():New(oSection1, oSection1:Cell("ZL6_DSUBEV")    ,"Total Sub Ev",.F.,"")
	TRFunction():New(oSection1:Cell("VALOR")  ,"","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T.)
	TRFunction():New(oSection1:Cell("QUANT")  ,"","SUM",oBreak1,,/*cPicture*/,/*uFormula*/,.F.,.T.)
EndIf

oSection1:SetTotalInLine(.F.)

Return oReport

/*
===============================================================================================================================
Programa----------: MEST009I
Autor-------------: Josue Danich Prestes
Data da Criacao---: 31/10/2014
Descricao---------: Gera planilha de custos
Parametros--------: oReport - objeto de impressao
Retorno-----------:
===============================================================================================================================
*/
Static Function MEST009I(oReport)

Local oSection1 	:= oReport:Section(1)
Local _nVlrSin		:= 0
Local _nQtdSin		:= 0
Local _lErro		:= .F.
Local cProdDesc 	:= ""
Local _cUsuario 	:= ""
Local cCodUser	:= ""

oSection1:Init()
oReport:SetMeter(10)
oReport:IncMeter()

While ZL6T->(!Eof())
	_lErro := .F.

	//Roda engine de dados de custo gerencial
	//MV_PAR01 - Tipo Grupo
	//MV_PAR02 - Grupo Custo
	//MV_PAR05 - Data inicial
	//MV_PAR06 - Data Final
	// Ultimo parâmetro indica que e a segunda etapa de leitura de varias tabelas com regras da ZL6 lida na primeira etapa
	oReport:IncMeter()
	_aretorno := U_MEST009E(MV_PAR01,MV_PAR02,MV_PAR05,MV_PAR06,2,)
	If _lLoop
		Return .F.
	EndIf

	oReport:SetMeter(10)
	If Select("TRB") # 0
		TRB->( DBGoTop() )
		oReport:SetMeter(("TRB")->(RecCount()))
		DBSelectArea("TRB")
		TRB->( DBGoTop() )
	EndIf	
	
	_nQtdSin 	:= _aretorno[1]
	_nVlrSin 	:= _aretorno[2]	
	
	While SELECT("TRB") # 0 .And. TRB->(!Eof()) .And. MV_PAR08 == 2	//Analitico
		oReport:IncMeter()
		If ZL6T->ZL6_QTD == "2"
			_nmul := -1
		Else
			_nmul := 1
		EndIf

		oSection1:Cell("ZL6_DGRCUS"):SetValue(AllTrim(ZL6T->ZL6_DGRCUS))
		oSection1:Cell("ZL6_DTPCUS"):SetValue(AllTrim(ZL6T->ZL6_DTPCUS))
		oSection1:Cell("ZL6_DESEVE"):SetValue(AllTrim(ZL6T->ZL6_DESEVE))
		oSection1:Cell("ZL6_DSUBEV"):SetValue(AllTrim(ZL6T->ZL6_DSUBEV))

		If ZL6T->ZL6_OBSERV == "1" //*
			oSection1:Cell("PRODCOD")	:SetValue(TRB->D1_COD)
			cPrdDesc := Posicione("SB1",1,xFilial("SB1")+TRB->D1_COD,"B1_DESC")
			oSection1:Cell("FILIAL")	:SetValue(TRB->D1_FILIAL)
			oSection1:Cell("PRODDESC")	:SetValue(cPrdDesc)
			oSection1:Cell("CODFORN")	:SetValue(TRB->F1_FORNECE)
			oSection1:Cell("DESFORN")	:SetValue(Posicione("SA2",1,xFilial("SA2")+TRB->F1_FORNECE,"A2_NOME"))
			oSection1:Cell("CFOP")		:SetValue(TRB->D1_CF)
			oSection1:Cell("QUANT")		:SetValue(TRB->D1_QUANT * _nmul)
			oSection1:Cell("VALOR")		:SetValue(TRB->D1_TOTAL * _nmul)
			oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->D1_DOC))
			oSection1:Cell("CCUSTO")	:SetValue(Posicione("CTT",1,xFilial("CTT")+TRB->D1_CC,"CTT_DESC01"))
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->D1_EMISSAO))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(TRB->D1_DTDIGIT))
			oSection1:Cell("TES")		:SetValue(AllTrim(TRB->D1_TES))
			oSection1:Cell("NUMSEQ")	:SetValue(AllTrim(TRB->D1_NUMSEQ))
					
			If (!Empty(TRB->F1_USERLGI) .And. !Empty(TRB->F1_USERLGA));
						.Or. (Empty(TRB->F1_USERLGI) .And. !Empty(TRB->F1_USERLGA))
				cCodUser := ""
				cCodUser := Subs(Embaralha(TRB->F1_USERLGA, 1), 3, 6)
				PswOrder(1)     // Busca por ID
					
				If PSWSEEK( cCodUser, .T. )
					aUser := PSWRET() // Retorna vetor com informacoes do usuario
					oSection1:Cell("USUARIO"):SetValue(aUser[1,2])
				Else
					oSection1:Cell("USUARIO"):SetValue("N/C")
				EndIf
			ElseIf !Empty(TRB->F1_USERLGI) .And. Empty(TRB->F1_USERLGA)
				cCodUser := ""
				cCodUser := Subs(Embaralha(TRB->F1_USERLGI, 1), 3, 6)
				PswOrder(1)     // Busca por ID
					
				If PSWSEEK( cCodUser, .T. )
					aUser := PSWRET() // Retorna vetor com informacoes do usuario
					oSection1:Cell("USUARIO"):SetValue(aUser[1,2])
				Else
					oSection1:Cell("USUARIO"):SetValue("N/C")
				EndIf
			EndIf
				
			oSection1:Cell("MAT")	:SetValue("")
			oSection1:Cell("PD")	:SetValue("")
			oSection1:Cell("TIPO1")	:SetValue("")
			oSection1:Cell("OBS")	:SetValue("")
		ElseIf ZL6T->ZL6_OBSERV == "2" 
			oSection1:Cell("PRODCOD"):SetValue(TRB->D2_COD)
			cPrdDesc := Posicione("SB1",1,xFilial("SB1")+TRB->D2_COD,"B1_DESC")
			oSection1:Cell("PRODDESC")	:SetValue(cPrdDesc)
			oSection1:Cell("CFOP")		:SetValue(TRB->D2_CF)
			oSection1:Cell("QUANT")		:SetValue(TRB->D2_QUANT * _nmul)
			If ZL6T->ZL6_D2FRET == 'S'
				oSection1:Cell("VALOR")		:SetValue(TRB->D2_I_FRET * _nmul)
			Else
				oSection1:Cell("VALOR")		:SetValue(TRB->D2_TOTAL * _nmul)
			EndIf		
			oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->D2_DOC))
			oSection1:Cell("CCUSTO")	:SetValue("")
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->D2_EMISSAO))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue(AllTrim(TRB->D2_TES))
			oSection1:Cell("NUMSEQ")	:SetValue(AllTrim(TRB->D2_NUMSEQ))
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")		:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue("")					
		ElseIf ZL6T->ZL6_OBSERV == "3"
			oSection1:Cell("PRODCOD")	:SetValue(TRB->D3_COD)
			cPrdDesc := Posicione("SB1",1,xFilial("SB1")+TRB->D3_COD,"B1_DESC")
			oSection1:Cell("FILIAL")	:SetValue(TRB->D3_FILIAL)
			oSection1:Cell("PRODDESC")	:SetValue(cPrdDesc)
			oSection1:Cell("CFOP")		:SetValue(TRB->D3_CF)
			oSection1:Cell("QUANT")		:SetValue(TRB->QUANT * _nmul)
			oSection1:Cell("VALOR")		:SetValue(TRB->D3_CUSTO1 * _nmul)
			oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->D3_DOC))
			oSection1:Cell("CCUSTO")	:SetValue(Posicione("CTT",1,xFilial("CTT")+TRB->D3_CC,"CTT_DESC01"))
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->D3_EMISSAO))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue(AllTrim(TRB->D3_TM))
			oSection1:Cell("NUMSEQ")	:SetValue(AllTrim(TRB->D3_NUMSEQ))
			oSection1:Cell("USUARIO")	:SetValue(TRB->D3_USUARIO)
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")		:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue(TRB->D3_I_OBS)
		ElseIf ZL6T->ZL6_OBSERV == "4"//4
			If ZL6T->ZL6_TXFIN == "S" .And. !ZL6T->ZL6_RPA $ '1,2,3'
				oSection1:Cell("FILIAL")	:SetValue(TRB->E2_FILIAL)
			ElseIf ZL6T->ZL6_RPA == "1" 	//RPA
				oSection1:Cell("FILIAL")	:SetValue(TRB->ZZ2_FILIAL)
			ElseIf ZL6T->ZL6_RPA == "2" 	//CAIXINHA
				oSection1:Cell("FILIAL")	:SetValue(TRB->EU_FILIAL)
			ElseIf ZL6T->ZL6_RPA == "3" 	//COMISSAO
				oSection1:Cell("FILIAL")	:SetValue(TRB->E3_FILIAL)
			Else//NENHUM
				oSection1:Cell("FILIAL")	:SetValue(TRB->E5_FILIAL)	
			EndIf	

			If ZL6T->ZL6_RPA = "2" //CAIXINHA
				oSection1:Cell("CODFORN")	:SetValue("")
				oSection1:Cell("DESFORN")	:SetValue(TRB->FORNEC)
			ElseIf ZL6T->ZL6_RPA = "3" //COMISSAO
				oSection1:Cell("CODFORN")	:SetValue(TRB->E3_VEND)
				oSection1:Cell("DESFORN")	:SetValue(TRB->A3_NOME)
			Else
				oSection1:Cell("CODFORN")	:SetValue(TRB->FORNEC)
				oSection1:Cell("DESFORN")	:SetValue(Posicione("SA2",1,xFilial("SA2")+TRB->FORNEC,"A2_NOME"))
			EndIf

			oSection1:Cell("PRODCOD")		:SetValue("")
			oSection1:Cell("PRODDESC")		:SetValue("")
			oSection1:Cell("CFOP")			:SetValue("")
			oSection1:Cell("QUANT")			:SetValue("")
			oSection1:Cell("VALOR")			:SetValue(TRB->VALOR * _nmul)
			If !ZL6T->ZL6_RPA $ '1,2,3'
				oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->E5_NUMERO))
			ElseIf ZL6T->ZL6_RPA ="1"
				oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->ZZ2_RECIBO))
			ElseIf ZL6T->ZL6_RPA ="2"
				oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->EU_NRCOMP))
			ElseIf ZL6T->ZL6_RPA ="3"
				oSection1:Cell("DOC")		:SetValue(AllTrim(TRB->E3_NUM))
			EndIf		
			oSection1:Cell("CCUSTO")		:SetValue("")
			If !ZL6T->ZL6_RPA $ '1,2,3' 
				oSection1:Cell("NATUREZA")	:SetValue(TRB->E5_NATUREZ)
			EndIf	
			If !ZL6T->ZL6_RPA $ '1,2,3'
				oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->E5_DATA))
			ElseIf ZL6T->ZL6_RPA ="1"
				oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->ZZ2_DATA))
			ElseIf ZL6T->ZL6_RPA ="2"
				oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->EU_DTDIGIT))
			ElseIf ZL6T->ZL6_RPA ="3"
				oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->E3_EMISSAO))
			EndIf		
			oSection1:Cell("DTDIGIT")		:SetValue(SToD(""))
			oSection1:Cell("TES")			:SetValue("")
			oSection1:Cell("NUMSEQ")		:SetValue("")
				
			oSection1:Cell("MAT")	:SetValue("")
			oSection1:Cell("PD")	:SetValue("")           	
			oSection1:Cell("TIPO1")	:SetValue("")
			If !ZL6T->ZL6_RPA $ '1,2,3' .And. ZL6T->ZL6_TXFIN <> 'S'
				oSection1:Cell("OBS")	:SetValue(TRB->E5_HISTOR)
			ElseIf ZL6T->ZL6_RPA ="2"
				oSection1:Cell("OBS")	:SetValue(TRB->EU_HISTOR)
			Else	
				oSection1:Cell("OBS")	:SetValue("")
			EndIf	
		ElseIf ZL6T->ZL6_OBSERV == "5" 
			oSection1:Cell("FILIAL")	:SetValue(TRB->BC_FILIAL)
			oSection1:Cell("PRODCOD")	:SetValue(TRB->BC_PRODUTO)
			oSection1:Cell("PRODDESC")	:SetValue(TRB->BC_I_NPROD)
			oSection1:Cell("CFOP")		:SetValue("")
			oSection1:Cell("QUANT")		:SetValue(TRB->BC_QUANT * _nmul)
			oSection1:Cell("VALOR")		:SetValue(TRB->BC_I_CUSTO * _nmul)
			oSection1:Cell("DOC")		:SetValue(TRB->BC_OP)
			oSection1:Cell("CCUSTO")	:SetValue(Posicione("CTT",1,xFilial("CTT")+TRB->BC_CC,"CTT_DESC01"))
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(TRB->BC_DATA))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue("")
			oSection1:Cell("NUMSEQ")	:SetValue(TRB->BC_NUMSEQ)
			oSection1:Cell("USUARIO")	:SetValue("")
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")		:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue("")						
		ElseIf ZL6T->ZL6_OBSERV == "6" 
			oSection1:Cell("FILIAL")	:SetValue(ZL6T->ZL6_FILIS)
			oSection1:Cell("PRODCOD")	:SetValue("")
			oSection1:Cell("PRODDESC")	:SetValue("")
			oSection1:Cell("CFOP")		:SetValue("")
			oSection1:Cell("QUANT")	:SetValue(0)
			oSection1:Cell("VALOR")		:SetValue(TRB->TOTAL_GERAL * _nmul)
			oSection1:Cell("DOC")		:SetValue("")
			oSection1:Cell("CCUSTO")	:SetValue("")
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(""))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue("")
			oSection1:Cell("NUMSEQ")	:SetValue("")
			oSection1:Cell("USUARIO")	:SetValue("")
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")		:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue("")										
		ElseIf ZL6T->ZL6_OBSERV == "7" 
			oSection1:Cell("FILIAL")	:SetValue(ZL6T->ZL6_FILIS)
			oSection1:Cell("PRODCOD")	:SetValue("")
			oSection1:Cell("PRODDESC")	:SetValue("")
			oSection1:Cell("CFOP")		:SetValue("")
			oSection1:Cell("QUANT")	:SetValue(TRB->RD_HORAS * _nmul)
			oSection1:Cell("VALOR")		:SetValue(TRB->RD_VALOR * _nmul)
			oSection1:Cell("DOC")		:SetValue("")
			oSection1:Cell("CCUSTO")	:SetValue("")
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(""))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue("")
			oSection1:Cell("NUMSEQ")	:SetValue("")
			oSection1:Cell("USUARIO")	:SetValue("")
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")		:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue("")										
		ElseIf ZL6T->ZL6_OBSERV == "8" 
			oSection1:Cell("FILIAL")	:SetValue(TRB->B9_FILIAL)
			oSection1:Cell("PRODCOD")	:SetValue(TRB->B9_COD)
			oSection1:Cell("PRODDESC")	:SetValue(Posicione("SB1",1,xFilial("SB1")+TRB->B9_COD,"B1_DESC"))
			oSection1:Cell("CFOP")		:SetValue("")
			oSection1:Cell("QUANT")	:SetValue(TRB->B9_QINI * _nmul)
			oSection1:Cell("VALOR")		:SetValue(TRB->B9_VINI1 * _nmul)
			oSection1:Cell("DOC")		:SetValue("")
			oSection1:Cell("CCUSTO")		:SetValue("")
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(""))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue("")
			oSection1:Cell("NUMSEQ")		:SetValue("")
			oSection1:Cell("USUARIO")	:SetValue("")
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")			:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")
			oSection1:Cell("OBS")		:SetValue("")										
		ElseIf ZL6T->ZL6_OBSERV == "9" 
			If ZL6T->ZL6_TERCEI = "S"
				oSection1:Cell("PRODCOD")	:SetValue("")
			Else	
				oSection1:Cell("PRODCOD")	:SetValue(TRB->ZLF_A2COD)
			EndIf
			If ZL6T->ZL6_TERCEI = "S"
				oSection1:Cell("PRODDESC")	:SetValue("")
			Else	
				oSection1:Cell("PRODDESC")	:SetValue(Posicione("SA2",1,xFilial("SA2")+TRB->ZLF_A2COD,"A2_NOME"))
			EndIf	
			oSection1:Cell("CFOP")		:SetValue("")
			oSection1:Cell("QUANT")	:SetValue(TRB->QUANT * _nmul)
			oSection1:Cell("VALOR")		:SetValue((TRB->CREDITO - TRB->DEBITO) * _nmul)
			oSection1:Cell("DOC")		:SetValue("")
			oSection1:Cell("CCUSTO")		:SetValue("")
			oSection1:Cell("NATUREZA")	:SetValue("")
			oSection1:Cell("EMISSAO")	:SetValue(SToD(""))
			oSection1:Cell("DTDIGIT")	:SetValue(SToD(""))
			oSection1:Cell("TES")		:SetValue("")
			oSection1:Cell("NUMSEQ")		:SetValue("")
			oSection1:Cell("USUARIO")	:SetValue("")
			oSection1:Cell("MAT")		:SetValue("")
			oSection1:Cell("PD")			:SetValue("")
			oSection1:Cell("TIPO1")		:SetValue("")                       
			oSection1:Cell("OBS")		:SetValue("")										
		EndIf
			
		oSection1:PrintLine()				
		
		cProdDesc := ""
		_cUsuario := ""
		
		If oReport:Cancel()
			Exit
		EndIf
		
		TRB->(DBSkip())
	End

	If ( MV_PAR08 == 1 .And. !_lErro ) .Or. ( ZL6T->ZL6_OBSERV $ "A,B,C,D" )
		oSection1:Cell("ZL6_DGRCUS"):SetValue(AllTrim(ZL6T->ZL6_DGRCUS))
		oSection1:Cell("ZL6_DTPCUS"):SetValue(AllTrim(ZL6T->ZL6_DTPCUS))
		oSection1:Cell("ZL6_DESEVE"):SetValue(AllTrim(ZL6T->ZL6_DESEVE))
		oSection1:Cell("ZL6_DSUBEV"):SetValue(AllTrim(ZL6T->ZL6_DSUBEV))
		
		If ZL6T->ZL6_OBSERV <> "4" 
			oSection1:Cell("QUANT")	:SetValue(_nQtdSin)
		Else
			oSection1:Cell("QUANT")	:SetValue(0)
		EndIf
		
		oSection1:Cell("VALOR")	:SetValue(_nVlrSin)
		
		oSection1:PrintLine()
		oReport:IncMeter()
	EndIf
		
	_nVlrSin := 0
	_nQtdSin := 0
		
	If Select("TRB") # 0
		TRB->(DBCloseArea())
	EndIf	
	
	If oReport:Cancel()
		Exit
	EndIf
	
	ZL6T->(DBSkip())
EndDo

oSection1:Finish()
ZL6T->(DBCloseArea())

Return .T.

/*
===============================================================================================================================
Programa----------: MEST009K
Autor-------------: Josue Danich Prestes
Data da Criacao---: 06/11/2015
Descricao---------: Realiza validacao das Datas
Parametros--------: Nenhum
Retorno-----------: .T. se validou ou .F. se encontrou data invalida
===============================================================================================================================
*/

Static Function MEST009K(oTProcess)

Local _lRet := .T.

If MV_PAR05 > MV_PAR06
	U_ITMsg("'Emissao De' maior que 'Emissao Ate'.","Data invalida","A data final tem que ser maior que a inicial",1)
	_lRet := .F.
Else
	If ValType(oTProcess) = "O"
		oTProcess:SetRegua1( 3 )
		oTProcess:IncRegua1("Ainda Processando, Aguarde..." )
		oTProcess:IncRegua1("Ainda Processando, Aguarde..." )
	EndIf
EndIf

Return( _lRet )

/*
===============================================================================================================================
Programa----------: MEST009E
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Engine de dados de custo gerencial
Parametros--------: 	_cTpGrupo	Tipo Grupo
						_cGrupo	Grupo Custo
						_dinicial	Data inicial
						_dfinal	Data Final
						_netapa	1 -	indica que e a primeira etapa de leitura da ZL6
									2 -	indica que e a segunda etapa de leitura de varias tabelas com regras da ZL6 
										lida na primeira etapa	
Retorno-----------: _aretorno - para etapa 1 retorna quantidade de registros lidos na ZL6
					   _aretorno - para etapa 2 retorna matriz {_nQtdSin, _nVlrSin} com quantidade e valor encontrados
					   				 para a regra
===============================================================================================================================
*/
User Function MEST009E(_cTpGrupo,_cGrupo,_dinicial,_dfinal,_netapa,_oself,_lEnd)
 
Local _cQuery		:= ""
Local _cquery2		:= ""
Local _nRegZL6		:= 0
Local _nVlrSin		:= 0
Local _nQtdSin		:= 0
Local _aretorno		:= {} 
Local _nVlrMix		:= 0
Local _nVMixSF		:= 0
Local _CstMix		:= 0   , _zi  , E , _Am
Local _cEmpresa		:= SubStr(FWFilialName( cEmpAnt , xFilial("ZL6") , 2 ),8,35)
Local _aProd        := {} , _nI

Default _cTpGrupo 	:= ""
Default _cGrupo		:= ""
Default _netapa 	:= 1
Default _dinicial	:= Date()//ctod('01/01/2020')
Default _dfinal		:= Date()//ctod('01/01/2049')
Default _oSelf      := ""
Default _lEnd       :=.F.

If _lEnd 
   _lLoop:=.T.
   If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
      Return {}
   EndIf   
EndIf

Private _aProdsRateio:={}////Variavel usada na função MEST9Rateio(_CodProd)

//Carrega Valor do Mix do leite
DBSelectArea("ZL2")
Zl2->( DBSetOrder(2) )

If Empty(MV_PAR10)
	If ZL2->( DBSeek( xFilial("ZL2") + AllTrim(_cempresa)) )
		If ZL2->ZL2_DTUMIX >= _dinicial .And. ZL2->ZL2_DTUMIX <= ( _dfinal + 15 )
			_nVlrMix := ZL2->ZL2_ULTMIX
			_nVMixSF := ZL2->ZL2_ULMISF
		Else
			_nVlrMix := MV_PAR10
		EndIf
	Else
		_nVlrMix := MV_PAR10
	EndIf
Else				
	_nVlrMix := MV_PAR10
EndIf
DBCloseArea()	

//Carrega regras de custo gerencial
If _netapa == 1
    _oSelf:IncRegua1("LENDO ETAPA 1 DO ZL6..." )
	If Select("ZL6T") > 0 
		ZL6T->( DBCloseArea() )
	EndIf
 
	_cQuery	:= " SELECT  * " 
	_cQuery  	+= " FROM " + RetSqlName("ZL6") + " ZL6 "
	_cQuery  	+= " WHERE ZL6_FILIAL = '" + xFilial("ZL6") + "'"
	_cQuery  	+=  IIf(!Empty(AllTrim(_cTpGrupo))	," AND   ZL6_TPCUS  IN "+ FormatIn(AllTrim(_cTpGrupo),";")	,"")	
	_cQuery  	+=  IIf(!Empty(AllTrim(_cGrupo))	," AND   ZL6_GRPCUS IN "+ FormatIn(AllTrim(_cGrupo),";")	,"")
	_cQuery  	+=  IIf(!Empty(AllTrim(MV_PAR03))	," AND   ZL6_CODEVE IN "+ FormatIn(AllTrim(MV_PAR03),";")	,"")
	_cQuery  	+=  IIf(!Empty(AllTrim(MV_PAR04))	," AND   ZL6_SUBEVE IN "+ FormatIn(AllTrim(MV_PAR04),";")	,"")		
	_cQuery  	+= " AND   ZL6_MSBLQL <> '1' 	"
	_cQuery 	+= " AND   ZL6.D_E_L_E_T_ 	= ' '	"
	_cQuery  	+= " ORDER BY ZL6_OBSERV, ZL6_TPCUS, ZL6_GRPCUS, ZL6_CODEVE, ZL6_SUBEVE " 

    MPSysOpenQuery( _cQuery, "ZL6T" ) 

	DBSelectArea("ZL6T")
  	COUNT To _nRegZL6
	
	ZL6T->( DBGoTop() )
	_aretorno := { _nRegZL6 }	
EndIf

//Carrega dados de custo gerencial
If _netapa == 2
	If MV_PAR07 == 3 .And. ValType(_oSelf) = "O"
	    _oself:IncRegua2(ZL6T->ZL6_OBSERV+" - "+AllTrim(ZL6T->ZL6_DSUBEV))
	EndIf
	
	If Select("TRB") > 0 
		TRB->( DBCloseArea() )
	EndIf
	
	//Nota Fiscal de entrada
	If  ZL6T->ZL6_OBSERV == "1" 		
		_cquery2	:= U_MEST0091(_dinicial,_dfinal) //Rotina que carrega query  de nota fiscal de entrada	
	//Nota Fiscal de saída
	ElseIf ZL6T->ZL6_OBSERV == "2"
		_cquery2	:= U_MEST0092(_dinicial,_dfinal) //Rotina que carrega query  de nota fiscal de saída		
	//Movim. Interno
	ElseIf ZL6T->ZL6_OBSERV == "3" 	
		_cquery2	:= U_MEST0093(_dinicial,_dfinal) //Rotina que carrega query  de movimentos internos
	//Financeiro
	ElseIf ZL6T->ZL6_OBSERV == "4" 	
		_cquery2	:= U_MEST0094(_dinicial,_dfinal) //Rotina que carrega query  de financeiro
	//Perdas por OP
	ElseIf ZL6T->ZL6_OBSERV == "5" //ATE AQUI TRATA DATA TIPO P-PERIODO 25 A 26
		_cquery2	:= U_MEST0095(_dinicial,_dfinal) //Rotina que carrega query  de perdas por op
	//Mao de Obra
	ElseIf  ZL6T->ZL6_OBSERV == "6"
		_cquery2 := ""
		_aVlrSin := U_MEST0096(_dinicial,_dfinal) //Rotina que carrega qtde e valor de funcionarios
		_nVlrSin := _aVlrSin[1]
		_nQtdSin := _aVlrSin[2]
	//Hora Extra
	ElseIf  ZL6T->ZL6_OBSERV == "7"
		_cquery2	:= U_MEST0097(_dinicial,_dfinal) //Rotina que carrega query  de hora extra
	//Saldos iniciais
	ElseIf  ZL6T->ZL6_OBSERV == "8"
		_cquery2	:= U_MEST0098(_dinicial,_dfinal) //Rotina que carrega query  de saldos iniciais
	//Gestão do Leite
	ElseIf  ZL6T->ZL6_OBSERV == "9"
		_cquery2	:= U_MEST0099(_dinicial,_dfinal) //Rotina que carrega query  de gestão de leite
	//Frete Proporcional
	ElseIf  ZL6T->ZL6_OBSERV == "A"
		_cquery2 := ""
		_aVlrSin := U_MEST009A(_dinicial,_dfinal)
		_nVlrSin := _aVlrSin[1]
		_nQtdSin := _aVlrSin[2]
	//Valores Manual
	ElseIf  ZL6T->ZL6_OBSERV == "B"
		_cquery2 := ""
		_nVlrSin := ZL6T->ZL6_MVALOR
		_nQtdSin := ZL6T->ZL6_MQTDE				
	//NFE + ST
	ElseIf  ZL6T->ZL6_OBSERV == "C"
		_cquery2 := ""
		_aVlrSin := MEST009IST( AllTrim(ZL6T->ZL6_CODPRO) )
		_nVlrSin := _aVlrSin[1,1]
	//CUSTO GERENCIAL FECHADO
	ElseIf  ZL6T->ZL6_OBSERV == "D" .And. AllTrim(ZL6T->ZL6_TPCUS) <> '000005'
		_cquery2 := ""    
		_aVlrSin := MEST9BuscaZE0(AllTrim(ZL6T->ZL6_FILIS),AllTrim(ZL6T->ZL6_CLIENTE),AllTrim(ZL6T->ZL6_CODPRO),AllTrim(ZL6T->ZL6_TPCUS))
		_nQtdSin := _aVlrSin[1]
		_nVlrSin := _aVlrSin[2]
	//PARA O DEMONSTRATIVO DO ESTOQUE FINAL PLANILHA 03 Grupo (000006) OU (PLANILHA 02 PASTA 2 Grupos (000004/000005) )
	ElseIf  ZL6T->ZL6_OBSERV == "E" .And. (_lGera3Pla .Or. (_lGera2Pla .Or. _lGera1Pla))
		_cquery2 := ""    
		_aVlrSin := MEST9EstoqueFinal(_oself,@_lEnd)
		_nVlrSin := _aVlrSin[1]
		_nQtdSin := _aVlrSin[2]
		_aProd   := _aVlrSin[3]
	//EXCEDENTE MATERIA GORDA
	ElseIf ZL6T->ZL6_OBSERV == "F" 	
		_cquery2 := ""    
		_aVlrSin := U_MEST9MGE(_dinicial,_dfinal)
		_nVlrSin := _aVlrSin[3]
		_nQtdSin := 0
        _lTemMateriaPrima:=.T.
	EndIf	

    If _lEnd 
       _lLoop:=.T.
       If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
          Return _aretorno
       EndIf   
    EndIf

	If !Empty(_cquery2)
       MPSysOpenQuery( _cQuery2 , "TRB" ) 
       DBSelectArea("TRB")
    EndIf
    
    _lTemEstoquenaDT:=.F.
    _nQtdemKG:=0
    
	While !Empty(_cquery2) .And. TRB->(!Eof())
        If _lLoop
           Exit
        EndIf
	
		If ZL6T->ZL6_OBSERV == "1"
			_nVlrSin += TRB->D1_TOTAL
			_nQtdSin += TRB->D1_QUANT
		ElseIf ZL6T->ZL6_OBSERV == "2"
			If ZL6T->ZL6_D2FRET == 'S'
				_nVlrSin += TRB->D2_I_FRET
			Else
				_nVlrSin += TRB->D2_TOTAL
			EndIf	
			_nQtdSin += TRB->D2_QUANT
		ElseIf ZL6T->ZL6_OBSERV == "3"
	        If ZL6T->ZL6_MIX = "S" .And. _nVlrMix > 0
            	_CstMix := TRB->QUANT * _nVlrMix
				_nVlrSin += _CstMix
			ElseIf ZL6T->ZL6_MIX = "F" .And. _nVMixSF > 0
				_CstMix := TRB->QUANT * _nVMixSF
				_nVlrSin += _CstMix			
			ElseIf ZL6T->ZL6_MIX $ "P,L"
		        _lTemMateriaPrima:=.T.
			ElseIf !Empty(ZL6T->ZL6_GRPCUF)
				_nVlrSin := 0
			Else//If ZL6T->ZL6_MIX = "N"
				_nVlrSin += TRB->D3_CUSTO1
			EndIf	
		    _nQtdSin += TRB->QUANT
		    
		    If (nPos:=aScan(_aFactoMike, {|P| P[1] == AllTrim(TRB->D3_COD) })) <>  0
               _nQtdemKG+= (_aFactoMike[nPos,2] * TRB->QUANT)
		    EndIf
               
		ElseIf ZL6T->ZL6_OBSERV == "4"
			_nVlrSin += TRB->VALOR
		ElseIf ZL6T->ZL6_OBSERV == "5" 
			_nVlrSin += TRB->BC_I_CUSTO 
			_nQtdSin += TRB->BC_QUANT
		ElseIf ZL6T->ZL6_OBSERV == "6" 	
			_nQtdSin += TRB->QUANT
			_nVlrSin += TRB->TOTAL_GERAL
		ElseIf ZL6T->ZL6_OBSERV == "7" 	
			_nQtdSin += TRB->RD_HORAS
			_nVlrSin += TRB->RD_VALOR
		ElseIf ZL6T->ZL6_OBSERV == "8" 	
			_nQtdSin += TRB->B9_QINI
			_nVlrSin += TRB->B9_VINI1
			_lTemEstoquenaDT:=.T.
		ElseIf ZL6T->ZL6_OBSERV == "9" 	
			_nQtdSin += TRB->QUANT
			_nVlrSin += TRB->CREDITO - TRB->DEBITO
		EndIf
   
   		TRB->(DBSkip())
	End

	//Trabalha campos de multiplicação e divisão
	If ZL6T->ZL6_RCMUL > 0 .And. ZL6T->ZL6_OBSERV <> "7" .And. ZL6T->ZL6_OBSERV <> "6"
		_nVlrSin := _nVlrSin * ZL6T->ZL6_RCMUL
	EndIf
		
	If ZL6T->ZL6_RCDIV > 0.And. ZL6T->ZL6_OBSERV <> "7" .And. ZL6T->ZL6_OBSERV <> "6"
		_nVlrSin := _nVlrSin / ZL6T->ZL6_RCDIV
	EndIf

	//Caso produção em terceiros e perda contratual
	If ZL6T->ZL6_TERCEI = "S" .And. ZL6T->ZL6_TCMUL <> 0	
		_nQtdsin := _nQtdsin * ZL6T->ZL6_TCMUL
		_nVlrSin := _nVlrSin * ZL6T->ZL6_TCMUL	
	EndIf
	If ZL6T->ZL6_TERCEI = "S" .And. ZL6T->ZL6_TCDIV <> 0
		_nQtdsin := _nQtdsin / ZL6T->ZL6_TCDIV
		_nVlrSin := _nVlrSin / ZL6T->ZL6_TCDIV
	EndIf	
	
	//define se é regra unitária ou de quantidade
	If ZL6T->ZL6_CONTA == "N"
		_nQtdSin := 0
	EndIf
   
	If ZL6->(FIELDPOS("ZL6_RATCUS")) <> 0 .And. ZL6T->ZL6_RATCUS == "S" .And. !Empty(ZL6T->ZL6_PRDRAT) 
       _cChave:=xFilial("ZL6")+ZL6T->ZL6_GRPCUS+PadR(ZL6T->ZL6_DTPCUS,60)+PadR(ZL6T->ZL6_DGRCUS,40)+"PRODUTOS ACABADOS PRODUZIDOS            "
       _cValores:=_cChave+CRLF
	   _cProduto:= Posicione("ZL6",8,_cChave,"ZL6_CODPRO")
       _cValores+=_cProduto+CRLF

	   aProds:=StrTokArr(AllTrim(_cProduto), ';')

       _nVlrNew:=0
       _nQtdNew:=0
	   For _nI := 1 To Len(aProds)
		  nPer:=MEST9Rateio(aProds[_nI])
          _nVlrNew+=_nVlrSin*nPer
          _nQtdNew+=_nQtdsin*nPer

		  _cValores+="RETORNO: "+CRLF
		  _cValores+=aProds[_nI]+" - "+Str(nPer,22,7)+CRLF
		  _cValores+=aProds[_nI]+" - "+Str(_nVlrSin*nPer,22,7)+" - "+Str(_nQtdsin*nPer,22,7)+CRLF+CRLF
	   Next
	   _cValores+="TOTAL ORIGINAL: "+Str(_nVlrSin,22,7)+" - "+Str(_nQtdsin,22,7)+CRLF
	   _nQtdsin := _nQtdNew
	   _nVlrSin := _nVlrNew
	   _cValores+="TOTAL NOVO: "+Str(_nVlrSin,22,7)+" - "+Str(_nQtdsin,22,7)+CRLF

	   nHandle := FCreate(_cdir+"SELECT_RATEIO__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
       FWrite(nHandle, _cValores )
       FClose(nHandle)
	EndIf	   

   //monta array de retorno e alimenta array de total operacional
   If ZL6T->ZL6_QTD == "2" //.and.  _nVlrSin > 0
		_aretorno := { _nQtdSin * -1 , _nVlrSin * -1 , _lTemEstoquenaDT , _aProd , _nQtdemKG }	
	Else
		_aretorno := { _nQtdSin      , _nVlrSin      , _lTemEstoquenaDT , _aProd , _nQtdemKG }
	EndIf
EndIf

//Carrega total litros leite por consumo de materia prima
If _netapa == 3
    _oSelf:IncRegua1("LENDO ETAPA 3 DO ZL6..." )

	_cPosCap	:= SuperGetMV( "IT_POSTCAP",.F.,'')
	_cprods 	:= SuperGetMV( "IT_MPCUSTO",.F.,'')
	_cDesmontagem :=SuperGetMV( "IT_MPDESMO",.F.,"N")
	_cprodsPA 	:= SuperGetMV( "IT_PACUSTO",.F.,'')
	_cTransferencias:=SuperGetMV( "IT_PATRANS",.F.,"N")
	_cprodsCC 	:= SuperGetMV( "IT_MPCCUST",.F.,'')
	_cprodsCCPA	:= SuperGetMV( "IT_PACCUST",.F.,'')
	_cProdsRet  := SuperGetMV( "IT_RETCUST",.F.,'')
	_nProdsRet  := Val(SuperGetMV( "IT_CRETCUS",.F.,"4"))//	"1-Soma RE1" , "2-Desconta RE1" , "3-Soma RE7" , "4-Desconta RE7" , "5-Soma Ambos" ,"6-Desconta Ambos" 
    _nITVOLUAGUA:= SuperGetMV("IT_VOLUAGU",.F.,0)
    _nITOUTROMOV:= SuperGetMV("IT_OUTROMO",.F.,0)

	If MV_PAR11 = 2
		_cFilSom	:= ""
	ElseIf MV_PAR11 <> 2
		_cFilSom	:= SuperGetMV("IT_FILSOMA",.F.,'')
	EndIf	 

    _cValores:=""

	If Select("SD3T") > 0 
		SD3T->( DBCloseArea() )
	EndIf

	_cQuery	:= " SELECT " 
	_cQuery += " SUM(SD3.D3_QUANT) AS TOT " 
	_cQuery += " FROM " + RetSqlName("SD3") + " SD3 "
	If !Empty(_cFilSom)
		_cQuery += " WHERE SD3.D3_FILIAL IN " + FormatIn(AllTrim(_cFilSom),";")
	Else	
		_cQuery += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
	EndIf	
	_cQuery  += " AND   SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
	_cQuery  += " AND   SD3.D3_ESTORNO <> 'S' "
	_cQuery  += " AND   SD3.D_E_L_E_T_ = ' '	"

    _cQuery1:=_cQuery2:=_cquery3:="" 
	_nVolLeite:=0

	If cfilant $ (_cPosCap)
        _aFils :=StrTokArr(_cPosCap,';')
        _cSetor:=""
        For _nI := 1 To Len(_aFils)
            If ZLT->(DBSeek(xFilial()+_aFils[_nI]))
               _cSetor+=AllTrim(ZLT->ZLT_SETOR)//Pega os setores das filiais
               If RIGHT(_cSetor,1) <> ";"
                  _cSetor+=";"
               EndIf
            EndIf   
        Next              
        _cSetor:=LEFT(_cSetor, Len(_cSetor)-1 )
        _nVolLeite:=VolLeite(_cSetor) //VOLUME
  		_cprods:=_cprodsPA:=_cProdsRet:=""
	Else	
	    If !Empty(_cprods)
		   _cquery1 += " AND SD3.D3_COD IN " + FormatIn(AllTrim(_cprods),";")
	        If _cDesmontagem = "S"//SE SIM 
		       _cquery1 += " AND SD3.D3_CF  = 'DE7' "
			ElseIf _cDesmontagem = "A"//AMBOS
		       _cquery1 += " AND SD3.D3_CF  IN ('RE1','DE7') "   
			Else//If _cDesmontagem = "N"//NÃO
		       _cquery1 += " AND SD3.D3_CF  = 'RE1' "
	        EndIf
	        If !Empty(_cprodsCC)
	    	   _cquery1 	+= " AND SD3.D3_CC IN " + FormatIn(AllTrim(_cprodsCC),";")
	        EndIf
	    EndIf	
        If !Empty(_cprodsPA)
		   _cquery2 += " AND SD3.D3_COD IN " + FormatIn(AllTrim(_cprodsPA),";")
	        If _cTransferencias = "S"//SE SIM 
			   _cquery2 += " AND  SD3.D3_CF IN ('RE4') AND SD3.D3_I_TPTRS = '1'  "
		    ElseIf _cTransferencias = "A"//SE AMBOS
			   _cquery2 += " AND ( ( SD3.D3_CF IN ('PR0')  "
	           If !Empty(_cprodsCCPA)
	    	      _cquery2 	+= " AND SD3.D3_CC IN " + FormatIn(AllTrim(_cprodsCCPA),";")
	           EndIf
			   _cquery2 += " ) OR (SD3.D3_CF IN ('RE4')  AND SD3.D3_I_TPTRS = '1') ) "
		    Else//If _cTransferencias = "N"//SE NÃO
		       _cquery2 += " AND SD3.D3_CF IN ('PR0') "
	           If !Empty(_cprodsCCPA)
	    	      _cquery2 	+= " AND SD3.D3_CC IN " + FormatIn(AllTrim(_cprodsCCPA),";")
	           EndIf
            EndIf
   	    EndIf	
	    If !Empty(_cProdsRet)
	        If Str(_nProdsRet,1)  $ "1,2"//"1-Soma DE1" , "2-Desconta DE1" , "3-Soma RE7" , "4-Desconta RE7" , "5-Soma Ambos" ,"6-Desconta Ambos" 
                _cquery3+= " AND  SD3.D3_CF IN ('DE1') "
	        ElseIf Str(_nProdsRet,1)  $ "3,4"
                _cquery3+= " AND  SD3.D3_CF IN ('RE7') "
	        ElseIf Str(_nProdsRet,1)  $ "5,6"
                _cquery3+= " AND  SD3.D3_CF IN ('DE1','RE7') "
	        EndIf
	       	_cquery3	+= " AND SD3.D3_COD IN " + FormatIn(AllTrim(_cProdsRet),";")
	    EndIf
    EndIf

	_aretorno:= _nRegZL6:=_nRegZL6Aux:= 0
	_cValores+=_cQuery+_cquery1+CRLF+CRLF

    If !Empty(_cprods)
		MPSysOpenQuery( (_cQuery+_cquery1) ,"SD3T" ) 
		DBSelectArea("SD3T")
		COUNT To _nRegZL6Aux
		_nRegZL6+=_nRegZL6Aux
		SD3T->( DBGoTop() )
		_aretorno += SD3T->TOT
		_cValores+=Str(SD3T->TOT,21,8)+CRLF+CRLF
    EndIf	
	_cValores+=_cQuery+_cquery2+CRLF+CRLF

	If Select("SD3T") > 0 
		SD3T->( DBCloseArea() )
	EndIf
    If !Empty(_cprodsPA)
		MPSysOpenQuery( (_cQuery+_cquery2) ,"SD3T" ) 
		DBSelectArea("SD3T")
		_nRegZL6Aux:=0
		COUNT To _nRegZL6Aux
		_nRegZL6+=_nRegZL6Aux
		SD3T->( DBGoTop() )
		_aretorno += SD3T->TOT
		_cValores+=Str(SD3T->TOT,21,8)+CRLF+CRLF
    EndIf
	If Select("SD3T") > 0 
		SD3T->( DBCloseArea() )
	EndIf
	_cValores+=_cQuery+_cquery3+CRLF+CRLF
    If !Empty(_cProdsRet)
		MPSysOpenQuery( (_cQuery+_cquery3) ,"SD3T" ) 
		DBSelectArea("SD3T")
		_nRegZL6Aux:=0
		COUNT To _nRegZL6Aux
		_nRegZL6+=_nRegZL6Aux
		SD3T->( DBGoTop() )
		_cValores+=Str(_aretorno,21,8)+CRLF+CRLF
		If Str(_nProdsRet,1)  $ "1,3,5"//"1-Soma RE1" , "2-Desconta RE1" , "3-Soma RE7" , "4-Desconta RE7" , "5-Soma Ambos" ,"6-Desconta Ambos" 
			_aretorno += SD3T->TOT
		ElseIf Str(_nProdsRet,1)  $ "2,4,6"
			_aretorno -= SD3T->TOT
		EndIf
		_cValores+=SuperGetMV("IT_CRETCUS",.F.,"4")+";"+Str(SD3T->TOT,21,8)+CRLF+CRLF
    EndIf

  	_cValores+="_nVolLeite: "+Str(_nVolLeite,21,8)+CRLF+CRLF

	_aretorno+=_nVolLeite
    _aretorno+=_nITVOLUAGUA
    _aretorno+=_nITOUTROMOV

  	_cValores+="_nITVOLUAGUA: "+Str(_nITVOLUAGUA,22,8)+CRLF+CRLF
  	_cValores+="_nITOUTROMOV: "+Str(_nITOUTROMOV,22,8)+CRLF+CRLF
  	_cValores+="_aretorno: "+Str(_aretorno,21,8)+CRLF+CRLF
  	
    _aretorno := { _aretorno,0 }

    _cFileNome:=_cdir+"MEST009_LEITE_MP_"+xFilial("ZL6")+"_"+StrTran(TIME(),":","_")+".TXT"
    MemoWrite(_cFileNome,_cValores)
EndIf

If _lEnd 
   If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
      _lLoop:=.T.
      Return _aretorno
   EndIf   
EndIf

// Se For a filial de Jaru tem um cálculo específico para total de consumo de soro
If _netapa == 3 .And. cfilant == "10" 
    _oSelf:IncRegua1("LENDO ETAPA 3 FILIAL 10 DO ZL6..." )
    _cData:= LastDate(MonthSub(MV_PAR06,1))

    _aPlanilia:={}                    //3,4,5,6,7,8,9,10
    aAdd(_aPlanilia,{'08000000029',1.00,0,0,0,0,0,0,0,1.00})
    aAdd(_aPlanilia,{'08000000049',9.16,0,0,0,0,0,0,0,3.08})
    aAdd(_aPlanilia,{'08000000056',3.10,0,0,0,0,0,0,0,3.08})
    aAdd(_aPlanilia,{'TOTAIS'     ,   0,0,0,0,0,0,0,0,0   })

	//1 - ESTOQUE INICIAL - POS 3
	If Select("SB9T") > 0 
	   SB9T->( DBCloseArea() )
	EndIf

	_cB9query := " SELECT B9_COD, SUM(B9_QINI) QTDE FROM " + retsqlname("SB9") 
	_cB9query += " WHERE D_E_L_E_T_ = ' ' "
	_cB9query += " AND B9_COD IN ('08000000029','08000000049','08000000056') "
	_cB9query += " AND B9_FILIAL = '" +cFilAnt+"'
	_cB9query += " AND B9_DATA = '" +DToS(_cData) + "'
	_cB9query += " GROUP BY B9_COD"
   
    MPSysOpenQuery( _cB9query ,"SB9T" ) 
    DBSelectArea("SB9T")
	
    _lTemSaldoIni:=.F.
	While ! SB9T->( Eof() )
	   If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SB9T->B9_COD) })) # 0
           _aPlanilia[nPos,3]:=SB9T->QTDE
           _lTemSaldoIni:=.T.
       EndIf
       SB9T->( DBSkip() )
	EndDo

    If !_lTemSaldoIni
        _aLocal:={"01","03","04"}
	    For _zi := 1 To Len(_aPlanilia)
	        For _Am := 1 To Len(_aLocal)
		        _aSaldos := CalcEst( _aPlanilia[_zi,1] , _aLocal[_Am] , _cData+1  ) //obtém o saldo final em estoque na data informada	
		        _aPlanilia[_zi,3]+=_aSaldos[1]
	        Next	
	    Next	
    EndIf

	//2 - PRODUÇÃO POS - 4
	If Select("SD3P") > 0 
	   SD3P->( DBCloseArea() )
	EndIf
	_cD3Pquery	:= " SELECT SD3.D3_COD, SUM(SD3.D3_QUANT) AS QTDE" 
	_cD3Pquery 	+= " FROM " + RetSqlName("SD3") + " SD3 "
	_cD3Pquery  += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
	_cD3Pquery  += " AND   SD3.D3_COD IN ('08000000029','08000000049','08000000056') " 
	_cD3Pquery  += " AND   SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
 	_cD3Pquery  += " AND   (SD3.D3_CF  = 'PR0' OR SD3.D3_CF  = 'DE1')"
	_cD3Pquery  += " AND   SD3.D3_ESTORNO <> 'S' "
	_cD3Pquery 	+= " AND   SD3.D_E_L_E_T_ = ' '	"
	_cD3Pquery  += " GROUP BY SD3.D3_COD"

    MPSysOpenQuery( _cD3Pquery ,"SD3P" ) 
    DBSelectArea("SD3P")

	While ! SD3P->( Eof() )
		If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SD3P->D3_COD) })) # 0
			_aPlanilia[nPos,4]:=SD3P->QTDE
			_lTemSaldoIni:=.T.
		EndIf
		SD3P->( DBSkip() )
	EndDo

	//3 - COMPRAS  - POS 5
	If Select("SD1C") > 0 
		SD1C->( DBCloseArea() )
	EndIf
	_cD1Cquery	:= " SELECT SD1.D1_COD, SUM(SD1.D1_QUANT) AS QTDE" 
	_cD1Cquery  += " FROM " + RetSqlName("SD1") + " SD1 "
	_cD1Cquery  += " WHERE SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
	_cD1Cquery  += " AND   SD1.D1_COD IN ('08000000029','08000000049','08000000056') "
	_cD1Cquery  += " AND   SD1.D1_DTDIGIT BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
 	_cD1Cquery  += " AND   SD1.D1_TES <> ' ' "
	_cD1Cquery 	+= " AND   SD1.D_E_L_E_T_ 	= ' '	"
	_cD1Cquery  += " GROUP BY SD1.D1_COD"

    MPSysOpenQuery( _cD1Cquery ,"SD1C" ) 
    DBSelectArea("SD1C")

	While ! SD1C->( Eof() )
		If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SD1C->D1_COD) })) # 0
			_aPlanilia[nPos,5]:=SD1C->QTDE
			_lTemSaldoIni:=.T.
		EndIf
		SD1C->( DBSkip() )
	EndDo

	//4 - SAIDA PROD. SORO PÓ - POS 6
	If Select("SD3S") > 0 
		SD3S->( DBCloseArea() )
	EndIf
	_cD3Squery	:= " SELECT SD3.D3_COD, SUM(SD3.D3_QUANT) AS QTDE" 
	_cD3Squery  += " FROM " + RetSqlName("SD3") + " SD3 "
	_cD3Squery  += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
	_cD3Squery  += " AND   SD3.D3_COD IN ('08000000029', '08000000049','08000000056') "
	_cD3Squery  += " AND   SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
	_cD3Squery  += " AND   SD3.D3_CF = 'RE1' "
	_cD3Squery  += " AND   SD3.D3_CC IN ('24191001')"
	_cD3Squery  += " AND   SD3.D3_ESTORNO <> 'S' "
	_cD3Squery 	+= " AND   SD3.D_E_L_E_T_ = ' '	"
    _cD3Squery  += " GROUP BY SD3.D3_COD"

    MPSysOpenQuery( _cD3Squery ,"SD3S" ) 
    DBSelectArea("SD3S")

	While ! SD3S->( Eof() )
		If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SD3S->D3_COD) })) # 0
			_aPlanilia[nPos,6]:=SD3S->QTDE
			_lTemSaldoIni:=.T.
		EndIf
		SD3S->( DBSkip() )
	EndDo

	//5 - SAIDA PROD. COMPOSTO  - POS 7
	If Select("SD3C") > 0 
		SD3C->( DBCloseArea() )
	EndIf
	_cD3Cquery	:= " SELECT SD3.D3_COD, SUM(SD3.D3_QUANT) AS QTDE" 
	_cD3Cquery  += " FROM " + RetSqlName("SD3") + " SD3 "
	_cD3Cquery  += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
	_cD3Cquery  += " AND   SD3.D3_COD IN ('08000000029', '08000000049','08000000056') "
	_cD3Cquery  += " AND   SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
	_cD3Cquery 	+= " AND   SD3.D3_CF        = 'RE1' "
	_cD3Cquery 	+= " AND   SD3.D3_CC IN ('24132001')"
	_cD3Cquery  += " AND   SD3.D3_ESTORNO <> 'S' "
	_cD3Cquery 	+= " AND   SD3.D_E_L_E_T_ = ' '	"
	_cD3Cquery  += " GROUP BY SD3.D3_COD"

    MPSysOpenQuery( _cD3Cquery ,"SD3C" ) 
    DBSelectArea("SD3C")

	While ! SD3C->( Eof() )
		If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SD3C->D3_COD) })) # 0
			_aPlanilia[nPos,7]:=SD3C->QTDE
			_lTemSaldoIni:=.T.
		EndIf
		SD3C->( DBSkip() )
	EndDo

	//6 - SAIDA DEVOLUÇÃO - POS 8
	If Select("SD2C") > 0 
		SD2C->( DBCloseArea() )
	EndIf
	_cD2query	:= " SELECT SD2.D2_COD, SUM(SD2.D2_QUANT) AS QTDE" 
	_cD2query  	+= " FROM " + RetSqlName("SD2") + " SD2 "
	_cD2query  	+= " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
	_cD2query  	+= " AND   SD2.D2_COD IN ('08000000029','08000000049','08000000056') "
	_cD2query  	+= " AND   SD2.D2_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
 	_cD2query  	+= " AND   SD2.D2_TIPO = 'D' "
	_cD2query 	+= " AND   SD2.D_E_L_E_T_ 	= ' '	"
	_cD2query 	+= " GROUP BY SD2.D2_COD "

    MPSysOpenQuery( _cD2query ,"SD2C" ) 
    DBSelectArea("SD2C")

	While ! SD2C->( Eof() )
		If (nPos:=aScan(_aPlanilia,{|P| P[1]==AllTrim(SD2C->D2_COD) })) # 0
			_aPlanilia[nPos,8]:=SD2C->QTDE
			_lTemSaldoIni:=.T.
		EndIf
		SD2C->( DBSkip() )
	EndDo

	//7 - ESTOQUE FINAL - POS 9
     nPos:=Len(_aPlanilia)//TOTAIS
     For E := 1 To (nPos-1)
		If SB5->(FIELDPOS("B5_I_FATR1")) # 0
			_nFator1:=Posicione("SB5",1,xFilial("SB5")+_aPlanilia[E,1],"B5_I_FATR1")
			_nFator2:=Posicione("SB5",1,xFilial("SB5")+_aPlanilia[E,1],"B5_I_FATR2")
			_aPlanilia[E,10]:= If(_nFator1=0,1,_nFator1)//Fator de conversao compra do soro  3.12
			_aPlanilia[E,02]:= If(_nFator2=0,1,_nFator1)//Fator de conversao de Rendimento 3.1,9,16
		EndIf   
		_aPlanilia[E,09]:= (_aPlanilia[E,3]+_aPlanilia[E,4]+_aPlanilia[E,5]) - (_aPlanilia[E,6]+_aPlanilia[E,7]+_aPlanilia[E,8])
     Next

	//CONTA MANUAL = FLUIDO - TOTAIS
	//    1          , 2  ,3,4,5,6,7,8,9, 10
	//1 '08000000029',1   ,0,0,0,0,0,0,0,1.0 }) 1
	//2 '08000000049',9.16,0,0,0,0,0,0,0,3.12}) 2
	//3 '08000000056',3.10,0,0,0,0,0,0,0,3.12}) 3
	//4 'TOTAIS'     ,   0,0,0,0,0,0,0,0,0   }) 4
	//  1            ,2   ,3,4,5,6,7,8,9
                            //linha 1                              linha 2                              linha 3
	_aPlanilia[nPos,3]:= (_aPlanilia[1,3]* _aPlanilia[1,02]) + (_aPlanilia[2,3]*_aPlanilia[2,02]) + (_aPlanilia[3,3]*_aPlanilia[3,02])//1-ESTOQUE INICIAL
	_aPlanilia[nPos,4]:=  _aPlanilia[1,4] //2-PRODUÇÃO
	_aPlanilia[nPos,5]:= (_aPlanilia[1,5]* _aPlanilia[1,10]) + (_aPlanilia[2,5]*_aPlanilia[2,10]) + (_aPlanilia[3,5]*_aPlanilia[3,10]) //3-COMPRAS
	_aPlanilia[nPos,7]:= (_aPlanilia[1,7]* _aPlanilia[1,02]) + (_aPlanilia[2,7]*_aPlanilia[2,02]) + (_aPlanilia[3,7]*_aPlanilia[3,02]) //5-SAIDA PROD. COMPOSTO
	_aPlanilia[nPos,8]:= (_aPlanilia[1,8]* _aPlanilia[1,10]) + (_aPlanilia[2,8]*_aPlanilia[2,10]) + (_aPlanilia[3,8]*_aPlanilia[3,10]) //6-SAIDA DEVOLUÇÃO
	_aPlanilia[nPos,9]:= (_aPlanilia[1,9]* _aPlanilia[1,02]) + (_aPlanilia[2,9]*_aPlanilia[2,02]) + (_aPlanilia[3,9]*_aPlanilia[3,02]) //5-SAIDA PROD. COMPOSTO

	_aPlanilia[nPos,6]:= (_aPlanilia[4,3]+_aPlanilia[4,4]+_aPlanilia[4,5]) - (_aPlanilia[4,7]+_aPlanilia[4,8]+_aPlanilia[4,9])//CALCULO MANUAL

	_aretorno[2] := _aPlanilia[nPos,6]

	//1 - ESTOQUE INICIAL - POS 3
	If Select("SB9T") > 0 
		SB9T->( DBCloseArea() )
	EndIf
	//2 - PRODUÇÃO POS - 4
	If Select("SD3P") > 0 
		SD3P->( DBCloseArea() )
	EndIf
	//3 - COMPRAS  - POS 5
	If Select("SD1C") > 0 
		SD1C->( DBCloseArea() )
	EndIf
	//4 - SAIDA PROD. SORO PÓ - POS 6
	If Select("SD3S") > 0 
		SD3S->( DBCloseArea() )
	EndIf
	//5 - SAIDA PROD. COMPOSTO  - POS 7
	If Select("SD3C") > 0 
		SD3C->( DBCloseArea() )
	EndIf
	//6 - SAIDA DEVOLUÇÃO - POS 8
	If Select("SD2C") > 0 
		 SD2C->( DBCloseArea() )
	EndIf
	DBSelectArea("ZL6")
EndIf

Return _aretorno

/*
===============================================================================================================================
Programa----------: MEST0091
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de notas de entrada
Parametros--------: 	_dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0091(_dinicial,_dfinal)

Local _cquery2 := ""
Local _cTabela	:= "SD1.D1"
Local _cTabela2 	:= "SF1.F1"

_cQuery2 	:= " SELECT "
	
//escolhe valor total ou custo padrao do Protheus
If ZL6T->ZL6_EXIMPO == "S"
	If ZL6T->ZL6_PISCOF == "S"
		_cQuery2 	+= " 			(D1_CUSTO + D1_VALIMP5 + D1_VALIMP6) AS D1_TOTAL,"
	Else
		_cQuery2 	+= " 			D1_CUSTO AS D1_TOTAL,"
	EndIf
Else
	If ZL6T->ZL6_PISCOF == "S"
		If ZL6T->ZL6_ABTDES = "S"
			_cQuery2 	+= " 			(((D1_TOTAL+D1_VALFRE) - D1_VALDESC) - (D1_VALIMP5 + D1_VALIMP6)) AS D1_TOTAL,"
		Else	
			_cQuery2 	+= " 			((D1_TOTAL+D1_VALFRE) - (D1_VALIMP5 + D1_VALIMP6)) AS D1_TOTAL,"
		EndIf	
	Else
		If ZL6T->ZL6_ABTDES = "S"
			_cQuery2 	+= " 			((D1_TOTAL+D1_VALFRE) - D1_VALDESC) AS D1_TOTAL,"
		Else	
			_cQuery2 	+= " 			(D1_TOTAL+D1_VALFRE) AS D1_TOTAL,"
		EndIf	
	EndIf
EndIf
If ZL6T->ZL6_TUNID == 'S'
	_cQuery2	+= " 			D1_QTSEGUM D1_QUANT,"
Else
	_cQuery2	+= " 			D1_QUANT,"
EndIf
_cQuery2 	+= " 			D1_COD,"
_cQuery2 	+= " 			D1_CF,"
_cQuery2 	+= " 			D1_DOC,"
_cQuery2 	+= " 			D1_CC,"
_cQuery2 	+= " 			D1_EMISSAO,"
_cQuery2 	+= " 			D1_DTDIGIT,"
_cQuery2 	+= " 			D1_TES,"
_cQuery2 	+= " 			D1_NUMSEQ,"
_cQuery2 	+= " 			F1_FORNECE,"
_cQuery2 	+= " 			F1_USERLGA,"
_cQuery2 	+= " 			F1_USERLGI,"
_cQuery2 	+= " 			(SELECT SUM(E2_VALOR) FROM "+ RetSqlName("SE2") + " SE2"
_cQuery2 	+= "          						 WHERE SE2.E2_FILIAL		= SD1.D1_FILIAL	AND "
_cQuery2 	+= "											SE2.E2_FORNECE 	= SD1.D1_FORNECE 	AND "
_cQuery2 	+= "											SE2.E2_LOJA 		= SD1.D1_LOJA		AND "
_cQuery2 	+= "											SE2.E2_NUM			= SD1.D1_DOC     	AND "		
_cQuery2 	+= "											SE2.D_E_L_E_T_ = ' ') AS E2_VALOR,"
_cQuery2 	+= " 			(SELECT E2_NATUREZ FROM "+ RetSqlName("SE2") + " SE2"
_cQuery2 	+= "          						 WHERE SE2.E2_FILIAL		= SD1.D1_FILIAL	AND "
_cQuery2 	+= "											SE2.E2_FORNECE	= SD1.D1_FORNECE 	AND "
_cQuery2 	+= "											SE2.E2_LOJA 		= SD1.D1_LOJA		AND "
_cQuery2 	+= "											SE2.E2_NUM			= SD1.D1_DOC     	AND "	
_cQuery2 	+= "											ROWNUM = 1 AND"			
_cQuery2 	+= "											SE2.D_E_L_E_T_ = ' ') AS E2_NATUREZ,"
_cQuery2 	+= " 			D1_FILIAL"		
_cQuery2 	+= " FROM "+ RetSqlName("SD1")+ " SD1 "
_cQuery2 	+= " INNER JOIN "+ RetSqlName("SF1")+" SF1 ON 	SF1.F1_FILIAL 	= SD1.D1_FILIAL	AND "
_cQuery2 	+= "  													SF1.F1_FORNECE	= SD1.D1_FORNECE 	AND "
_cQuery2 	+= "  													SF1.F1_LOJA 		= SD1.D1_LOJA		AND " 
_cQuery2 	+= "  													SF1.F1_SERIE 		= SD1.D1_SERIE	AND " 
_cQuery2 	+= "  													SF1.F1_DOC 		= SD1.D1_DOC "

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE SD1.D1_FILIAL = '" + xFilial("SD1") + "'"
Else
	_cQuery2 += " WHERE SD1.D1_FILIAL IN " +  FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf

If AllTrim(ZL6T->ZL6_PRXMES) == "S"
	nMonth := 1
	_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
	_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
	nMonth := 1
	_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
	_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
	_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
	_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)

	If MONTH(_dinicial) = 2 
		If Val(_cDiaI) > 28
			_cDiaI:="28"
		EndIf   
		If Val(_cDiaF) > 28
			_cDiaF:="28"
		EndIf   
	EndIf

	If MONTH(_dinicial) > 1
		_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
	Else
		_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
	EndIf
	_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
EndIf

If AllTrim(ZL6T->ZL6_VENCTO) == "S"
	_cQuery2 += " AND	(SELECT E2_VENCTO FROM "+ RetSqlName("SE2") + " SE2"
	_cQuery2 	+= "          						 WHERE SE2.E2_FILIAL		= SD1.D1_FILIAL	AND "
	_cQuery2 	+= "											SE2.E2_FORNECE 	= SD1.D1_FORNECE 	AND "
	_cQuery2 	+= "											SE2.E2_LOJA 		= SD1.D1_LOJA		AND "
	_cQuery2 	+= "											SE2.E2_NUM			= SD1.D1_DOC     	AND "	
	_cQuery2 	+= "											ROWNUM		= 1     	AND "		
	_cQuery2 	+= "											SE2.D_E_L_E_T_ = ' ')  BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
ElseIf AllTrim(ZL6T->ZL6_VENCTO) == "D"
	_cQuery2 += " AND SD1.D1_DTDIGIT BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
Else
	_cQuery2 += " AND SD1.D1_EMISSAO BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
EndIf
				
_cQuery2 	+= " AND SD1.D1_TES > ' ' "

If !Empty(ZL6T->ZL6_CFOP)
	_cQuery2	+= " AND " + _cTabela + "_CF  IN " + FormatIn(AllTrim(ZL6T->ZL6_CFOP),";")
EndIf

If !Empty(ZL6T->ZL6_NCFOP)
	_cQuery2	+= " AND " + _cTabela + "_CF  NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCFOP),";")
EndIf

If  !Empty(ZL6T->ZL6_LOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL IN " + FormatIn(AllTrim(ZL6T->ZL6_LOCAL),";")
EndIf

If  !Empty(ZL6T->ZL6_NLOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NLOCAL),";")
EndIf

If	!Empty(ZL6T->ZL6_CENTRO)
	_cQuery2 	+= " AND " + _cTabela + "_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
EndIf

If	!Empty(ZL6T->ZL6_NCENTR)
	_cQuery2 	+= " AND " + _cTabela + "_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
EndIf

If	!Empty(ZL6T->ZL6_TES)
	_cQuery2 	+= " AND " + _cTabela + "_TES IN " + FormatIn(AllTrim(ZL6T->ZL6_TES),";")
EndIf

If	!Empty(ZL6T->ZL6_NTES)
	_cQuery2 	+= " AND " + _cTabela + "_TES NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTES),";")
EndIf

If	 !Empty(ZL6T->ZL6_NATURE)
	_cQuery2 	+= " AND		(SELECT E2_NATUREZ FROM "+ RetSqlName("SE2") + " SE2"
	_cQuery2 	+= "          						 WHERE SE2.E2_FILIAL		= SD1.D1_FILIAL	AND "
	_cQuery2 	+= "											SE2.E2_FORNECE 	= SD1.D1_FORNECE 	AND "
	_cQuery2 	+= "											SE2.E2_LOJA 		= SD1.D1_LOJA		AND "
	_cQuery2 	+= "											SE2.E2_NUM			= SD1.D1_DOC     	AND "	
	_cQuery2 	+= "											ROWNUM = 1 AND"			
	_cQuery2 	+= "											SE2.D_E_L_E_T_ = ' ') IN " + FormatIn(AllTrim(ZL6T->ZL6_NATURE),";")
EndIf

If	 !Empty(ZL6T->ZL6_NNATUR)
	_cQuery2 	+= " AND		(SELECT E2_NATUREZ FROM "+ RetSqlName("SE2") + " SE2"
	_cQuery2 	+= "          						 WHERE SE2.E2_FILIAL		= SD1.D1_FILIAL	AND "
	_cQuery2 	+= "											SE2.E2_FORNECE 	= SD1.D1_FORNECE 	AND "
	_cQuery2 	+= "											SE2.E2_LOJA 		= SD1.D1_LOJA		AND "
	_cQuery2 	+= "											SE2.E2_NUM			= SD1.D1_DOC     	AND "	
	_cQuery2 	+= "											ROWNUM = 1 AND"			
	_cQuery2 	+= "											SE2.D_E_L_E_T_ = ' ') NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NNATUR),";")
EndIf

If	 !Empty(ZL6T->ZL6_CODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NCODPR)
	_cQuery2 += " AND " + _cTabela + "_COD NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCODPR),";")
EndIf	

If  !Empty(ZL6T->ZL6_TPROD)
	_cQuery2 += " AND " + _cTabela + "_TP IN " + FormatIn(AllTrim(ZL6T->ZL6_TPROD),";")
EndIf

If  !Empty(ZL6T->ZL6_NTPRO)
	_cQuery2 += " AND " + _cTabela + "_TP NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTPRO),";")
EndIf

If !Empty(ZL6T->ZL6_GRPPRO)
	_cQuery2 += " AND " + _cTabela + "_GRUPO IN " + FormatIn(AllTrim(ZL6T->ZL6_GRPPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NGRPPR)
	_cQuery2 += " AND " + _cTabela + "_GRUPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NGRPPR),";")
EndIf

If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

If !Empty(ZL6T->ZL6_FORNEC)
	_cQuery2 += " AND " + _cTabela + "_FORNECE IN " + FormatIn(AllTrim(ZL6T->ZL6_FORNEC),";")
EndIf

If !Empty(ZL6T->ZL6_NFORNE)
	_cQuery2 += " AND " + _cTabela + "_FORNECE NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NFORNE),";")
EndIf

If  !Empty(ZL6T->ZL6_TNOTA)
	_cQuery2 += " AND " + _cTabela + "_TIPO IN " + FormatIn(AllTrim(ZL6T->ZL6_TNOTA),";")
EndIf

If  !Empty(ZL6T->ZL6_NTNOT)
	_cQuery2 += " AND " + _cTabela + "_TIPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTNOT),";")
EndIf	 

_cQuery2 += " AND " + SubStr(_cTabela,1,4)  + "D_E_L_E_T_ = ' '"
_cQuery2 += " AND " + SubStr(_cTabela2,1,4)  + "D_E_L_E_T_ = ' '"

Return _cquery2

/*
===============================================================================================================================
Programa----------: MEST0092
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de notas de saída
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0092(_dinicial,_dfinal)

Local _cquery2 := ""
Local _cTabela	:= "SD2.D2"

_cQuery2 	:= " SELECT "
_cQuery2 	+= " 			D2_COD,"
_cQuery2 	+= " 			D2_CF,"
If ZL6T->ZL6_TUNID == 'S'
	_cQuery2	+= " 			D2_QTSEGUM D2_QUANT,"
Else
	_cQuery2	+= " 			D2_QUANT,"
EndIf
_cQuery2 	+= " 			D2_I_FRET,"
_cQuery2 	+= " 			D2_DOC,"
_cQuery2 	+= " 			D2_EMISSAO,"
_cQuery2 	+= " 			D2_TES,"
_cQuery2 	+= " 			D2_NUMSEQ,"
_cQuery2 	+= " 			D2_TOTAL,"
_cQuery2 	+= " 			D2_QUANT"
_cQuery2 	+= " FROM "+ RetSqlName("SD2")+ " SD2 "
					
If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
Else
	_cQuery2 += " WHERE  SD2.D2_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf
								
If AllTrim(ZL6T->ZL6_PRXMES) == "S"
	nMonth := 1
	_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
	_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
	nMonth := 1
	_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
	_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)

	_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
	_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
	If MONTH(_dinicial) = 2 
		If Val(_cDiaI) > 28
			_cDiaI:="28"
		EndIf   
		If Val(_cDiaF) > 28
			_cDiaF:="28"
		EndIf   
	EndIf

	If MONTH(_dinicial) > 1
		_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
	Else
		_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI)
	EndIf
	_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
EndIf

_cQuery2 += " AND " + _cTabela + "_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"		

If !Empty(ZL6T->ZL6_CFOP)
	_cQuery2	+= " AND "+_cTabela+"_CF  IN "+ FormatIn(AllTrim(ZL6T->ZL6_CFOP),";")
EndIf

If !Empty(ZL6T->ZL6_NCFOP)
	_cQuery2	+= " AND "+_cTabela+"_CF  NOT IN "+ FormatIn(AllTrim(ZL6T->ZL6_NCFOP),";")
EndIf

If  !Empty(ZL6T->ZL6_LOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL IN " + FormatIn(AllTrim(ZL6T->ZL6_LOCAL),";")
EndIf

If !Empty(ZL6T->ZL6_NESTAD)
	_cQuery2	+= " AND "+_cTabela+"_EST  NOT IN "+ FormatIn(AllTrim(ZL6T->ZL6_NESTAD),";")
EndIf

If  !Empty(ZL6T->ZL6_ESTADO)
	_cQuery2 += " AND " + _cTabela + "_EST IN " + FormatIn(AllTrim(ZL6T->ZL6_ESTADO),";")
EndIf

If  !Empty(ZL6T->ZL6_NLOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NLOCAL),";")
EndIf

If	!Empty(ZL6T->ZL6_CENTRO)
	_cQuery2 	+= " AND " + _cTabela + "_CCUSTO IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
EndIf

If	!Empty(ZL6T->ZL6_NCENTR)
	_cQuery2 	+= " AND " + _cTabela + "_CCUSTO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
EndIf

If	 !Empty(ZL6T->ZL6_CODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NCODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCODPRO),";")
EndIf	

If  !Empty(ZL6T->ZL6_TPROD)
	_cQuery2 += " AND " + _cTabela + "_TP IN " + FormatIn(AllTrim(ZL6T->ZL6_TPROD),";")
EndIf

If  !Empty(ZL6T->ZL6_NTPRO)
	_cQuery2 += " AND " + _cTabela + "_TP NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTPRO),";")
EndIf

If !Empty(ZL6T->ZL6_GRPPRO)
	_cQuery2 += " AND " + _cTabela + "_GRUPO IN "+ FormatIn(AllTrim(ZL6T->ZL6_GRPPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NGRPPR)
	_cQuery2 += " AND " + _cTabela + "_GRUPO IN "+ FormatIn(AllTrim(ZL6T->ZL6_NGRPPR),";")
EndIf

If !Empty(ZL6T->ZL6_FORNEC)
	_cQuery2 += " AND " + _cTabela + "_CLIENTE IN " + FormatIn(AllTrim(ZL6T->ZL6_FORNEC),";")
EndIf

If !Empty(ZL6T->ZL6_NFORNE)
	_cQuery2 += " AND " + _cTabela + "_CLIENTE NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NFORNE),";")
EndIf

If  !Empty(ZL6T->ZL6_TNOTA)
	_cQuery2 += " AND " + _cTabela + "_TIPO IN " + FormatIn(AllTrim(ZL6T->ZL6_TNOTA),";")
EndIf

If  !Empty(ZL6T->ZL6_NTNOT)
	_cQuery2 += " AND " + _cTabela + "_TIPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTNOT),";")
EndIf

If  ZL6T->ZL6_D2FRET == "S"
	_cQuery2 += " AND " + _cTabela + "_I_FRET <> 0"
EndIf


If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

_cQuery2 += " AND " + SubStr(_cTabela,1,4)  + "D_E_L_E_T_ = ' '"
_cQuery2 += " ORDER BY " + _cTabela + "_DOC, " + _cTabela + "_EMISSAO"

Return _cquery2

/*
===============================================================================================================================
Programa----------: MEST0093
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de movimentos internos
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0093(_dinicial,_dfinal)

Local _cquery2 	:= ""
Local _cTabela 	:= "SD3.D3"

_cQuery2 	:= " SELECT "
_cQuery2 	+= "  			D3_COD,"
_cQuery2 	+= "  			D3_CF,"
_cQuery2 	+= "  			D3_CC,"

//Se campo TUNID = 'S' manda quantidade na segunda unidade do produto 
If ZL6T->ZL6_TUNID == 'S'
	_cQuery2 	+= "        (Case WHEN (SELECT B1_CONV FROM " + RetSqlName("SB1") + " SB1 WHERE	SB1.D_E_L_E_T_ = ' ' AND 
	_cQuery2 	+= "																		   			ROWNUM = 1 AND"
	_cQuery2 	+= "																	          	SB1.B1_COD = SD3.D3_COD) > 0
	_cQuery2 	+= "		THEN	
	_cQuery2 	+= "			(Case 	WHEN (SELECT B1_TIPCONV FROM " + RetSqlName("SB1") + " SB1 WHERE SB1.D_E_L_E_T_ = ' ' AND ROWNUM = 1 AND"
	_cQuery2 	+= "																						SB1.B1_COD = SD3.D3_COD) = 'D'"
	_cQuery2 	+= "				THEN (D3_QUANT / (SELECT B1_CONV FROM " + RetSqlName("SB1") + " SB1 WHERE	SB1.D_E_L_E_T_ = ' ' AND 
	_cQuery2 	+= "																						   			ROWNUM = 1 AND"
	_cQuery2 	+= "																						          	SB1.B1_COD = SD3.D3_COD))"   
	_cQuery2 	+= "				Else(D3_QUANT * (SELECT B1_CONV FROM " + RetSqlName("SB1") + " SB1 WHERE	SB1.D_E_L_E_T_ = ' ' AND 
	_cQuery2 	+= "																						   			ROWNUM = 1 AND"
	_cQuery2 	+= "																					          	SB1.B1_COD = SD3.D3_COD)) 
	_cQuery2 	+= "					END)
	_cQuery2 	+= "  			Else D3_QUANT
	_cQuery2 	+= "  			END ) QUANT, "
Else
	_cQuery2 	+= "  			D3_QUANT QUANT,"
EndIf

_cQuery2 	+= "  			D3_CUSTO1,"
_cQuery2 	+= "  			D3_DOC,"
_cQuery2 	+= "			D3_EMISSAO,"
_cQuery2 	+= "  			D3_TM,"
_cQuery2 	+= "  			D3_NUMSEQ,"
_cQuery2 	+= "  			D3_USUARIO,"	
_cQuery2 	+= "  			D3_CUSTO1,"
_cQuery2 	+= "  			D3_FILIAL,"		
_cQuery2	+= "			D3_I_OBS"	
_cQuery2 	+= "  FROM " + RetSqlName("SD3") + " SD3 "		

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
Else
	_cQuery2 += " WHERE SD3.D3_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf

If AllTrim(ZL6T->ZL6_PRXMES) == "S"
	nMonth := 1
	_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
	_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
	nMonth := 1
	_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
	_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
	_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
	_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
	If MONTH(_dinicial) = 2 
		If Val(_cDiaI) > 28
			_cDiaI:="28"
		EndIf   
		If Val(_cDiaF) > 28
			_cDiaF:="28"
		EndIf   
	EndIf

	If MONTH(_dinicial) > 1
		_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
	Else
		_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
	EndIf
	_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
EndIf

_cQuery2 	+= " AND " + _cTabela + "_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"
_cQuery2 	+= " AND " + _cTabela + "_ESTORNO = ' ' "

If  !Empty(ZL6T->ZL6_LOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL IN " + FormatIn(AllTrim(ZL6T->ZL6_LOCAL),";")
EndIf

If  !Empty(ZL6T->ZL6_NLOCAL)
	_cQuery2 += " AND " + _cTabela + "_LOCAL NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NLOCAL),";")
EndIf

If  !Empty(ZL6T->ZL6_CF)
	_cQuery2 += " AND " + _cTabela + "_CF IN " + FormatIn(AllTrim(ZL6T->ZL6_CF),";")
EndIf
					
If  !Empty(ZL6T->ZL6_NCF)
	_cQuery2 += " AND " + _cTabela + "_CF NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCF),";")
EndIf


If  !Empty(ZL6T->ZL6_TPMOV)
	_cQuery2 += " AND " + _cTabela + "_TM IN " + FormatIn(AllTrim(ZL6T->ZL6_TPMOV),";")
EndIf

If  !Empty(ZL6T->ZL6_NTPMOV)
	_cQuery2 += " AND " + _cTabela + "_TM NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTPMOV),";")
EndIf

If  !Empty(ZL6T->ZL6_TPROD)
	_cQuery2 += " AND " + _cTabela + "_TIPO IN " + FormatIn(AllTrim(ZL6T->ZL6_TPROD),";")
EndIf

If  !Empty(ZL6T->ZL6_NTPRO)
	_cQuery2 += " AND " + _cTabela + "_TIPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTPRO),";")
EndIf

If	 !Empty(ZL6T->ZL6_CENTRO)
	_cQuery2 += " AND " + _cTabela + "_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
EndIf

If	 !Empty(ZL6T->ZL6_NCENTR)
	_cQuery2 += " AND " + _cTabela + "_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
EndIf

If	!Empty(ZL6T->ZL6_CODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NCODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCODPRO),";")
EndIf	

If	!Empty(ZL6T->ZL6_GRPPRO)
	_cQuery2 += " AND " + _cTabela + "_GRUPO IN " + FormatIn(AllTrim(ZL6T->ZL6_GRPPRO),";") 
EndIf

If !Empty(ZL6T->ZL6_ORIGEM)
	_cQuery2 += " AND " + _cTabela + "_I_ORIGE NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_ORIGEM),";")
EndIf	


If	!Empty(ZL6T->ZL6_NORIGE)
	_cQuery2 += " AND " + _cTabela + "_I_ORIGE NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NORIGE),";") 
EndIf


If	!Empty(ZL6T->ZL6_NGRPPR)
	_cQuery2 += " AND " + _cTabela + "_GRUPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NGRPPR),";") 
EndIf

If	ZL6T->ZL6_D3OBS == 'S'
	_cQuery2 += " AND " + _cTabela + "_I_OBS <> ''"
EndIf


If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

_cQuery2 	+= " AND " + SubStr(_cTabela,1,4) + "D_E_L_E_T_ = ' '"
_cQuery2 += " ORDER BY " + _cTabela + "_DOC, " + _cTabela + "_EMISSAO"

Return _cquery2 

/*
===============================================================================================================================
Programa----------: MEST9MGE
Autor-------------: Alex Wallauer
Data da Criacao---: 03/01/2019
Descricao---------: 
Parametros--------: _dinicial - data inicial de analise
					_dfinal   - data final e analise
Retorno-----------: 
===============================================================================================================================
*/ 
User Function MEST9MGE(_dinicial,_dfinal)

Local _cQueryW 	:= ""
Local _cquery2 	:= ""

_cQuery2 	:= " SELECT "
_cQuery2 	+= " (SUM(SD3.D3_QUANT)* B1_PESO) QTDEMKGS FROM " + RetSqlName("SD3") + " SD3 JOIN " + RetSqlName("SB1") + " ON D3_COD = B1_COD "

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
Else
	_cQuery2 += " WHERE SD3.D3_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf

_cQuery2 	+= " AND SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"
_cQuery2 	+= " AND SD3.D3_ESTORNO <> 'S' "

If  !Empty(ZL6T->ZL6_LOCAL)
	_cQuery2 += " AND " + "SD3.D3" + "_LOCAL IN " + FormatIn(AllTrim(ZL6T->ZL6_LOCAL),";")
EndIf

If  !Empty(ZL6T->ZL6_NLOCAL)
	_cQuery2 += " AND " + "SD3.D3" + "_LOCAL NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NLOCAL),";")
EndIf

If  !Empty(ZL6T->ZL6_CF)
	_cQuery2 += " AND " + "SD3.D3" + "_CF IN " + FormatIn(AllTrim(ZL6T->ZL6_CF),";")
EndIf
					
If	 !Empty(ZL6T->ZL6_CENTRO)
	_cQuery2 += " AND " + "SD3.D3" + "_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
EndIf

If	 !Empty(ZL6T->ZL6_NCENTR)
	_cQuery2 += " AND " + "SD3.D3" + "_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
EndIf

If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

_cQuery2 	+= " AND SD3.D_E_L_E_T_ = ' '"

If	!Empty(ZL6T->ZL6_CODPRO)
	_cQueryW := " AND SD3.D3_COD IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")+" GROUP BY B1_PESO "
EndIf		

MPSysOpenQuery( _cQuery2+_cQueryW ,"SD2T" ) 

_nQuantI:=SD2T->QTDEMKGS

SD2T->( DBCloseArea() )

If	!Empty(ZL6T->ZL6_GRPPRO)
	_cQueryW :=  " AND SD3.D3_GRUPO IN " + FormatIn(AllTrim(ZL6T->ZL6_GRPPRO),";")+" GROUP BY B1_PESO "
EndIf
		
MPSysOpenQuery( _cQuery2+_cQueryW ,"SD2T" ) 

_nQuantT:=0
While SD2T->(!Eof())
	_nQuantT+=SD2T->QTDEMKGS
	SD2T->(DBSkip())
EndDo 

SD2T->( DBCloseArea() )

Return {_nQuantI , _nQuantT , (_nQuantI/_nQuantT) }

/*
===============================================================================================================================
Programa----------: MEST0094
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de financeiro
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0094(_dinicial,_dfinal)

Local _cquery2 := ""
_cQuery2 := " SELECT "

If ZL6T->ZL6_RPA == '2' .Or. ZL6T->ZL6_RPA == '3'

	If AllTrim(ZL6T->ZL6_PRXMES) == "S"
		nMonth := 1
		_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
		_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
		nMonth := 1
		_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
		_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
		_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
		_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
		If MONTH(_dinicial) = 2 
			If Val(_cDiaI) > 28
				_cDiaI:="28"
			EndIf   
			If Val(_cDiaF) > 28
				_cDiaF:="28"
			EndIf   
		EndIf

		If MONTH(_dinicial) > 1
			_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
		Else
			_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
		EndIf
		_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
    EndIf
EndIf

If ZL6T->ZL6_RPA == '2'//CAIXINHA
	_cQuery2 += "	EU_VALOR VALOR,"
	_cQuery2 += "	EU_NUM     ,  "
	_cQuery2 += "	EU_NRCOMP  ,  "
	_cQuery2 += "	EU_EMISSAO ,  "
	_cQuery2 += "	EU_DTDIGIT ,  "
	_cquery2 += " 	EU_FILIAL  ,  "
	_cquery2 += " 	EU_HISTOR  ,  "
	_cquery2 += " 	EU_BAIXA   ,  "
	_cquery2 += " 	EU_BENEF AS FORNEC "
	_cQuery2 += "	FROM " + RETSQLNAME("SEU") + "  SEU "
	
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " WHERE SEU.EU_FILIAL = '" + xFilial("SEU")+ "'
	Else
		_cQuery2 += " WHERE SEU.EU_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf

	_cQuery2 += " 	AND SEU.EU_DTDIGIT BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'" 
	_cQuery2 += " 	AND SEU.D_E_L_E_T_ = ' '"
		
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf
	_cQuery2 += " ORDER BY EU_NRCOMP, EU_DTDIGIT "
   Return _cquery2 

ElseIf ZL6T->ZL6_RPA == '3' //COMISSAO
	_cQuery2 += "	E3_COMIS VALOR,"
	_cQuery2 += "	E3_NUM     ,  "
	_cQuery2 += "	E3_EMISSAO ,  "
	_cQuery2 += "	E3_DATA    ,  "
	_cquery2 += " 	E3_FILIAL  ,  "
	_cquery2 += " 	E3_VEND    ,  "
	_cquery2 += " 	A3_NOME       "
	_cQuery2 += "	FROM " + RETSQLNAME("SE3") + "  SE3 "
	_cQuery2 += "    JOIN " + RetSqlName("SA3") + " SA3 ON SA3.A3_COD = SE3.E3_VEND AND SA3.D_E_L_E_T_ = ' ' "

	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " WHERE SE3.E3_FILIAL = '" + xFilial("SE3")+ "'
	Else
		_cQuery2 += " WHERE SE3.E3_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf
	
	_cQuery2 += " 	AND SE3.E3_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'" 
	_cQuery2 += " 	AND SE3.D_E_L_E_T_ = ' '"
		
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf

	_cQuery2 += " ORDER BY E3_NUM, E3_DATA "
	Return _cquery2
EndIf
		
If ZL6T->ZL6_TXFIN == 'S' .And. !ZL6T->ZL6_RPA $ '1,2,3'
	_cQuery2 += " 			E2_VALOR + 
	_cQuery2 += "           NVL((SELECT SUM(E2_VALOR) FROM " + RETSQLNAME("SE2") + " TE22  WHERE 	TE22.D_E_L_E_T_ = ' ' AND"
	_cQuery2 += " 				         			                                        SE2.E2_FILIAL = TE22.E2_FILIAL AND"
	_cQuery2 += " 				         			                                        SE2.E2_TIPO = SubStr(TE22.E2_TITPAI,15,3) AND"
	_cQuery2 += " 				         			                                        SE2.E2_NUM = SubStr(TE22.E2_TITPAI,4,9) AND"
	_cQuery2 += " 				         			                                        SE2.E2_PREFIXO = SubStr(TE22.E2_TITPAI,1,3) AND"
	_cQuery2 += " 				         			                                        SE2.E2_PARCELA = SubStr(TE22.E2_TITPAI,13,2) AND"
	_cQuery2 += " 				         			                                        SE2.E2_FORNECE = SubStr(TE22.E2_TITPAI,18,6)),0) VALOR, "
	_cQuery2 += " 			E2_NUM AS E5_NUMERO,"
	_cQuery2 += "		 	E2_NATUREZ AS E5_NATUREZ,"
	_cQuery2 += "			E2_EMISSAO AS E5_DATA,"		
	_cQuery2 += "			E2_USERLGI AS E5_USERLGI,"	
	_cQuery2 += "			E2_USERLGA AS E5_USERLGA,"
	_cQuery2 += "			E2_FORNECE AS FORNEC, "
	_cQuery2 += " 			E2_HIST,"
	_cQuery2 += " 			E2_FILIAL "	
   	_cQuery2 += "			FROM " + RETSQLNAME("SE2") + "  SE2"
			
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " WHERE SE2.D_E_L_E_T_ = ' ' AND SE2.E2_FILIAL = '" + xFilial("SE5") + "'"
	Else
		_cQuery2 += " WHERE SE2.D_E_L_E_T_ = ' ' AND SE2.E2_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf
	
	If AllTrim(ZL6T->ZL6_PRXMES) == "S"
		nMonth := 1
		_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
		_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
		nMonth := 1
		_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
		_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
		_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
		_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
		If MONTH(_dinicial) = 2 
			If Val(_cDiaI) > 28
				_cDiaI:="28"
			EndIf   
			If Val(_cDiaF) > 28
				_cDiaF:="28"
			EndIf   
		EndIf

		If MONTH(_dinicial) > 1
			_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
		Else
			_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
		EndIf
		_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
    EndIf
	
	If AllTrim(ZL6T->ZL6_VENCTO) == "S"
		_cQuery2 += " 	AND SE2.E2_VENCTO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"
	ElseIf AllTrim(ZL6T->ZL6_VENCTO) == "D"
		_cQuery2 += " AND SE2.E2_MOVIMEN BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
	Else
		_cQuery2 += " 	AND SE2.E2_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"
	EndIf  	
		
	If	!Empty(ZL6T->ZL6_NATURE)
		_cQuery2 += " AND SE2.E2_NATUREZ IN " + FormatIn(AllTrim(ZL6T->ZL6_NATURE),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NNATUR)
		_cQuery2 += " AND SE2.E2_NATUREZ NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NNATUR),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5PREF)
		_cQuery2 += " AND SE2.E2_PREFIXO IN " + FormatIn(AllTrim(ZL6T->ZL6_E5PREF),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5PRE)
		_cQuery2 += " AND SE2.E2_PREFIXO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NE5PRE),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5TIPO)
		_cQuery2 += " AND SE2.E2_TIPO IN " + FormatIn(AllTrim(ZL6T->ZL6_E5TIPO),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5TIP)
		_cQuery2 += " AND SE2.E2_TIPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NE5TIP),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5BENE)
		_cQuery2 += " AND SE2.E2_BENEF LIKE '%" + AllTrim(ZL6T->ZL6_E5BENE) + "%'"
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5BEN)
		_cQuery2 += " AND SE2.E2_BENEF NOT LIKE '%" + AllTrim(ZL6T->ZL6_NE5BEN) + "%'"
	EndIf
		
	If !Empty(ZL6T->ZL6_FORNEC)
		_cQuery2 += " AND " +  "SE2.E2_FORNECE IN " + FormatIn(AllTrim(ZL6T->ZL6_FORNEC),";")
	EndIf
		
	If !Empty(ZL6T->ZL6_NFORNE)
		_cQuery2 += " AND "  + "SE2.E2_FORNECE NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NFORNE),";")
	EndIf
	
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf
	
	_cQuery2 += " ORDER BY SE2.E2_NUM, SE2.E2_EMISSAO"
ElseIf !ZL6T->ZL6_RPA $ '1,2,3'	
	_cQuery2 += " 			E5_VALOR VALOR,"
	_cQuery2 += " 			E5_NUMERO,"
	_cQuery2 += "			E5_NATUREZ,"
	_cQuery2 += "			E5_DATA,"		
	_cQuery2 += "			E5_USERLGI,"	
	_cQuery2 += "			E5_USERLGA,"
	_cQuery2 += "			E5_FILIAL,"
	_cQuery2 += "			E5_HISTOR,"
	_cQuery2 += "			E5_CLIFOR AS FORNEC  "
	_cQuery2 += "			FROM " + RETSQLNAME("SE5") + "  SE5 
		
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " WHERE SE5.E5_FILIAL = '" + xFilial("SE5")+ "'
	Else
		_cQuery2 += " WHERE SE5.E5_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")	//+ " AND SE2.E2_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf
		
	If AllTrim(ZL6T->ZL6_PRXMES) == "S"
		nMonth := 1
		_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
		_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
		nMonth := 1
		_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
		_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
	ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
		_cDiaI:=LEFT(ZL6T->ZL6_PERIOD,2)
		_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
		If MONTH(_dinicial) = 2 
			If Val(_cDiaI) > 28
				_cDiaI:="28"
			EndIf   
			If Val(_cDiaF) > 28
				_cDiaF:="28"
			EndIf   
		EndIf

		If MONTH(_dinicial) > 1
			_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
		Else
			_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
		EndIf
		_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
    EndIf
	
	_cQuery2 += " 	AND SE5.E5_DATA BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'" 
	_cQuery2 += " 	AND SE5.E5_LA = 'S'"
	_cQuery2 += " 	AND SE5.E5_TIPODOC <> 'EST' "
	_cQuery2 += " 	AND SE5.D_E_L_E_T_ = ' ' "
	_cQuery2 += " 	AND SE5.E5_SITUACA <> 'C' "
		
	If	!Empty(ZL6T->ZL6_NATURE)
		_cQuery2 += " AND SE5.E5_NATUREZ IN " + FormatIn(AllTrim(ZL6T->ZL6_NATURE),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NNATUR)
		_cQuery2 += " AND SE5.E5_NATUREZ NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NNATUR),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5PREF)
		_cQuery2 += " AND SE5.E5_PREFIXO IN " + FormatIn(AllTrim(ZL6T->ZL6_E5PREF),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5PRE)
		_cQuery2 += " AND SE5.E5_PREFIXO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NE5PRE),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5TIPO)
		_cQuery2 += " AND SE5.E5_TIPO IN " + FormatIn(AllTrim(ZL6T->ZL6_E5TIPO),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5TIP)
		_cQuery2 += " AND SE5.E5_TIPO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NE5TIP),";")
	EndIf
		
	If	!Empty(ZL6T->ZL6_E5BENE)
		_cQuery2 += " AND SE5.E5_BENEF LIKE '%" + AllTrim(ZL6T->ZL6_E5BENE) + "%'"
	EndIf
		
	If	!Empty(ZL6T->ZL6_NE5BEN)
		_cQuery2 += " AND SE5.E5_BENEF NOT LIKE '%" + AllTrim(ZL6T->ZL6_NE5BEN) + "%'"
	EndIf
		
	If !Empty(ZL6T->ZL6_FORNEC)
		_cQuery2 += " AND SE5.E5_CLIFOR IN " + FormatIn(AllTrim(ZL6T->ZL6_FORNEC),";")
	EndIf
		
	If !Empty(ZL6T->ZL6_NFORNE)
		_cQuery2 += " AND SE5.E5_CLIFOR NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NFORNE),";")
	EndIf
		
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf
		
	_cQuery2 += " ORDER BY SE5.E5_NUMERO, SE5.E5_DATA"
EndIf

Return _cquery2 

/*
===============================================================================================================================
Programa----------: MEST0095
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de perdas por op
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0095(_dinicial,_dfinal)

Local _cquery2 	:= ""
Local _cTabela 	:= "SBC.BC"

_cQuery2 	:= " SELECT "
_cQuery2 	+= " 			 BC_PRODUTO,"
_cQuery2 	+= " 			 BC_I_NPROD,"
If ZL6T->ZL6_TUNID == 'S'
	_cQuery2	+= " 			BC_QTSEGUM BC_QUANT,"
Else
	_cQuery2	+= " 			BC_QUANT,"
EndIf
_cQuery2 	+= " 			 BC_I_CUSTO,"
_cQuery2 	+= " 			 BC_OP,"
_cQuery2 	+= " 			 BC_CC,"
_cQuery2 	+= " 			 BC_DATA,"
_cQuery2 	+= " 			 BC_NUMSEQ,"
_cQuery2 	+= " 			 BC_FILIAL "
_cQuery2 	+= " FROM " + RetSqlName("SBC") + " SBC "

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE SBC.BC_FILIAL = '" + xFilial("SBC") + "'"
Else
	_cQuery2 += " WHERE SBC.BC_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf
	
If AllTrim(ZL6T->ZL6_PRXMES) == "S"
	nMonth := 1
	_dinicial := MonthSum( _dinicial , nMonth ) //Soma Meses em Uma Data
	_dfinal	  := MonthSum( _dfinal , nMonth ) //Soma Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "N"
	nMonth := 1
	_dinicial := MonthSub( _dinicial , nMonth ) //diminui Meses em Uma Data
	_dfinal	  := MonthSub( _dfinal , nMonth ) //diminui Meses em Uma Data	 
ElseIf AllTrim(ZL6T->ZL6_PRXMES) == "P" .And. ZL6->(FIELDPOS("ZL6_PERIOD")) <> 0 .And. !Empty(ZL6T->ZL6_PERIOD)
	_cDiaI:=LEFT (ZL6T->ZL6_PERIOD,2)
	_cDiaF:=RIGHT(ZL6T->ZL6_PERIOD,2)
	If MONTH(_dinicial) = 2 
		If Val(_cDiaI) > 28
			_cDiaI:="28"
		EndIf   
		If Val(_cDiaF) > 28
			_cDiaF:="28"
		EndIf   
	EndIf

	If MONTH(_dinicial) > 1
		_dinicial := SToD(AllTrim(Str( YEAR(_dinicial)   )) + StrZero((MONTH(_dinicial)-1),2)+_cDiaI)
	Else
		_dinicial := SToD(AllTrim(Str((YEAR(_dinicial)-1))) + "12"+_cDiaI) 
	EndIf
	_dfinal	     := SToD(AllTrim(Str( YEAR(_dfinal)     )) + StrZero((MONTH(_dfinal)),2)+_cDiaF)
EndIf
	_cQuery2 	+= " AND " + SubStr(_cTabela,1,4) + "D_E_L_E_T_ = ' '"
	_cQuery2 	+= " AND " + _cTabela + "_DATA BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"		
		
	If !Empty(ZL6T->ZL6_CODPRO)
		_cQuery2 += " AND " + _cTabela + "_PRODUTO IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")
	EndIf	
	
	If !Empty(ZL6T->ZL6_NCODPRO)
		_cQuery2 += " AND " + _cTabela + "_PRODUTO NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCODPRO),";")
	EndIf	
	
	If !Empty(ZL6T->ZL6_CENTRO)
		_cQuery2 += " AND (SELECT C2_CC FROM " + RetSqlName("SC2") + " SC2 WHERE SC2.C2_FILIAL = SBC.BC_FILIAL
		_cQuery2 += " 																	AND SC2.C2_NUM || SC2.C2_ITEM || SC2.C2_SEQUEN = SBC.BC_OP"
		_cQuery2 += " 																	AND ROWNUM = 1)  IN  " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
	EndIf	
	
	If !Empty(ZL6T->ZL6_NCENTR)
		_cQuery2 += " AND (SELECT C2_CC FROM " + RetSqlName("SC2") + " SC2 WHERE SC2.C2_FILIAL = SBC.BC_FILIAL
		_cQuery2 += " 																	AND SC2.C2_NUM || SC2.C2_ITEM || SC2.C2_SEQUEN = SBC.BC_OP"
		_cQuery2 += " 																	AND ROWNUM = 1)  NOT IN  " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
	EndIf	
			
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf
		
	_cQuery2 += " ORDER BY " + _cTabela + "_OP, " + _cTabela + "_DATA"
Return _cquery2   

/*
===============================================================================================================================
Programa----------: MEST0096
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de mao de obra
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0096(_dinicial,_dfinal)

Local _cquery2 	:= ""
Local _cQueryQ 	:= ""
Local _cQuery	:= ""
Local _cQuery1	:= ""
Local _cFecham	:= ""
Local _nQuant 	:= 0
Local _nValor   := 0
Local _nip,VV
Local _cDIncial := AllTrim(Str(YEAR(_dinicial)))+ StrZero(MONTH(_dinicial),2)
Local _cDFinal	:= AllTrim(Str(YEAR(_dfinal)))+ StrZero(MONTH(_dfinal),2)
Local _cFER:=SuperGetMV("IT_FERIAS",.F.,"11.107")//"11.107" //FÉRIAS	           11,107% - [Fixo]   
Local _cEFE:=0   //Encargos sob Férias	4,130% - [Fixo]  
Local _c13S:=SuperGetMV("IT_13SALA",.F.,"08.330")//"8.33"   //13º SALARIO	        8,330% - [Fixo]
Local _cE13:=0 //Encargos sob 13º	3,100% - [Fixo]
Local _cValores:= ""

_cFER:=If(Empty(_cFER),"11.107",_cFER)//"11.107" //FÉRIAS	           11,107% - [Fixo]   
_c13S:=If(Empty(_c13S),"08.330",_c13S)//"8.33"   //13º SALARIO	        8,330% - [Fixo]

//Buscar data do ultimo fechamento  
_cQuery1 := " SELECT MAX(RD_DATARQ) AS ULTF FROM " + RETSQLNAME("SRD") + " SRD "
_cQuery1 += " WHERE SRD.D_E_L_E_T_ = ' ' "
_cQuery1 += " AND RD_FILIAL = '" + xFilial("SRD") + "'"
_cQuery1 += " AND RD_ROTEIR = 'FOL' "

MPSysOpenQuery( _cquery1 ,"SRDU" ) 
DBSelectArea("SRDU")

_cValores+=_cquery1+CRLF

If !(SRDU->( Eof() ))
	_cFecham := SRDU->ULTF
	_cValores+="MAX(RD_DATARQ): "+_cFecham+CRLF+CRLF
EndIf		

SRDU->( DBCloseArea() )

//Prepara array com filiais para montar o union de queries de rh 
_afiliais := {}

If !(Empty(ZL6T->ZL6_FILIS))
	_nip := 1
	While _nip + 1 <= Len(AllTrim(ZL6T->ZL6_FILIS))
		aAdd(_afiliais,SubStr(AllTrim(ZL6T->ZL6_FILIS),_nip,2))
		_nip := _nip + 3
	EndDo
Else
	aAdd(_afiliais, xFilial("SRA"))	
EndIf

//Essa query e fixa e nao retorna valores para o relatorio analítico, somente retorna o total 
// do custo de mao de obra da filial e quantidade de funcionarios ativos
// Vai montar uma querie para cada filial fazendo union entre todas para dar a somatória final
_cFilsemSRX := ""
_nip := 1
For _nip := 1 To Len(_afiliais)
   //Busca Impostos - INSS, RAT(ACT), FGTS
   _cQuery := " SELECT SubStr(RCC_CONTEU,2,7) AS INSS, SubStr(RCC_CONTEU,12,6) AS ACT, SubStr(RCC_CONTEU,26,6) AS FGTS
   _cQuery += " FROM " + RETSQLNAME("RCC") + " RCC "
   _cQuery += " WHERE RCC.D_E_L_E_T_ = ' ' "
   _cQuery += " AND RCC_CODIGO = 'S037' "
   _cQuery += " AND SubStr(RCC_CONTEU,1,1) = '1'"
   _cQuery += " AND SubStr(RCC_FIL,1,2) = '" +_afiliais[_nip] + "'"
   _cQuery += " AND RCC_CHAVE = '"+SubStr(DToS(_dInicial),1,6)+"'"

   MPSysOpenQuery( _cQuery ,"SRXT" ) 
   DBSelectArea("SRXT")

   If !(SRXT->( Eof() ))
	  _nInss 	:= AllTrim(SRXT->INSS)
	  _nAct	 	:= AllTrim(SRXT->ACT)
	  _nFgts	:= AllTrim(SRXT->FGTS) //VALOR_SM
   Else
      _cFilsemSRX += _afiliais[_nip]+", "
      
	  _nInss:= "0"
      _nAct	:= "0"
	  _nFgts:= "0"
   EndIf

   SRXT->( DBCloseArea() )
   
   //Busca Impostos - TERCEIROS
   _cQuery := " SELECT SubStr(RCC_CONTEU,7,6) AS TERC "
   _cQuery += " FROM " + RETSQLNAME("RCC") + " RCC "
   _cQuery += " WHERE RCC.D_E_L_E_T_ = ' ' "
   _cQuery += " AND RCC_CODIGO = 'S038' "
   _cQuery += " AND SubStr(RCC_FIL,1,2) = '" +_AFILIAIS[_nip] + "'"
   _cQuery += " AND (SubStr(RCC_CHAVE,13,6) = '"+SubStr(DToS(_dInicial),1,6)+"'"
   _cQuery += "      OR  RCC_CHAVE = ' ') ORDER BY RCC_CHAVE DESC "                   

   MPSysOpenQuery( _cQuery ,"SRXV" ) 
   DBSelectArea("SRXV")
   DBGoTop()

   If !(SRXV->( Eof() ))
	  _nTerc:= AllTrim(SRXV->TERC)
   EndIf
   If Empty(_nTerc)
	  _nTerc:= "0"
   EndIf		
   
   SRXV->( DBCloseArea() )

   _cEFE:=(Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct))*(Val(_cFER))/100 //Encargos sob Férias	
   _cE13:=(Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct))*(Val(_c13S))/100 //Encargos sob 13º	

   _cDC :=Val(_nInss)+Val(_nFgts)+Val(_nTerc)+Val(_nAct) //VALOR_DC - 37,22
   _cDC :=Str(_cDC,7,3) //VALOR_DC - 37,22
 
   _cSMT:=Val(_nInss)+Val(_cFER) +_cEFE +Val(_nFgts)+Val(_nTerc)+Val(_nAct)//VALOR_SMT - 52.46336
   _cSMT:=Str(_cSMT,7,3)//VALOR_SMT - 52.46336
   
   _cEST:=Val(_cFER) +_cEFE
   _cEST:=Str(_cEST,7,3)

	//Quantidade de funcionários ativos
	_cQueryQ 	:= " SELECT  COUNT(RA_FILIAL)  QUANT "
	_cQueryQ 	+= "             FROM " + RETSQLNAME("SRA") + " WHERE "
	_cQueryQ 	+= "                          D_E_L_E_T_ = ' ' AND   "
	_cQueryQ 	+= "                          RA_FILIAL = '" + _afiliais[_nip] + "' AND "
	_cQueryQ 	+= "                          (RA_CATFUNC = 'M' OR RA_CATFUNC = 'E' OR RA_CATFUNC = 'H') AND "
	_cQueryQ 	+= "                          RA_ADMISSA <= '"+DToS(_dfinal)+"'  AND "
	_cQueryQ 	+= "                          (RA_DEMISSA = ' ' OR RA_DEMISSA > '"+DToS(_dfinal)+"')  "
    If !Empty(ZL6T->ZL6_CENTRO)		
	    _cQueryQ += " AND RA_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
	EndIf
	If !Empty(ZL6T->ZL6_NCENTR)
	   _cQueryQ  += " AND RA_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
	EndIf

   MPSysOpenQuery( _cQueryQ , "QUANTF" ) 
   DBSelectArea("QUANTF")
   DBGoTop()
   _cValores+=_cQueryQ+CRLF

   If !(QUANTF->( Eof() ))
       _nQuant+=QUANTF->QUANT
      _cValores+=_afiliais[_nip]+" / "+"QUANTIDADE: "+Str(QUANTF->QUANT,22,7)+CRLF+CRLF
   EndIf
   
   QUANTF->( DBCloseArea() )   
	//Quantidade de funcionários ativos
   
	// Se faixa de data dos parâmetros pertence pelo menos um dia à competência do MV_FOLMES puxa o SRC inteiro
	// para o resultado pois o RC_PERIODO pode conter datas fora do período mas ainda assim pertencer a competência do MV_FOLMES]
	For VV := 1 To 3
		_cquery2:= " SELECT "
		
		If (StrZero(YEAR(MV_PAR05),4) + StrZero(MONTH(MV_PAR05),2)) > _cFecham .OR.;
		   (StrZero(YEAR(MV_PAR06),4) + StrZero(MONTH(MV_PAR06),2)) > _cFecham
			//Total de verbas
			_cquery2 	+= " TMP2.TOTAL_GERAL  AS TOTAL_T FROM "
			
			If VV = 1//query com verbas com todos os impostos
				_cquery2 	+= " (SELECT "
				_cquery2 	+= "  (SUM(TMP.INSS+TMP.ACT+TMP.RAT_TERC+TMP.FGTS+TMP.FERIAS+TMP.DECIMO_TERC+TMP.FOLHA)+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_ESTAG),NULL,0,SUM(TMP.VALOR_ESTAG))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_MULTA_DEMIS),NULL,0,SUM(TMP.VALOR_MULTA_DEMIS))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_SM),NULL,0,SUM(TMP.VALOR_SM))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_ACD_INSS),NULL,0,SUM(TMP.VALOR_ACD_INSS))+"				
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_DC),NULL,0,SUM(TMP.VALOR_DC))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_SMT),NULL,0,SUM(TMP.VALOR_SMT))) AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_T
			ElseIf VV = 2//query com verbas sem impostos
				_cquery2 	+= " (SELECT "
				_cquery2 	+= " (SUM(TMP.FOLHA))"
				_cquery2 	+= " AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_SE
			ElseIf VV = 3//query com verbas FGTS
				_cquery2 	+= " (SELECT "
				_cquery2 	+= " (SUM(TMP.FOLHA+TMP.FGTS))"
				_cquery2 	+= " AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_F
			EndIf
			_cquery2 	+= " select "
			_cquery2 	+= " 		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nInss+")/100) as INSS,"
			_cquery2 	+= "    	((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nAct +")/100) as ACT,"
			_cquery2 	+= "  		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nTerc+")/100) as RAT_TERC,"
			_cquery2 	+= "  		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nFgts+")/100) as FGTS,"
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) + "
			_cquery2 	+= " 	 	(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nInss+")/100) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nAct +")/100) + " 
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nTerc+")/100) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) *(("+_nFgts+")/100) )) as Ferias, "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nInss+")/100) + " 
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nAct +")/100) + "
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nTerc+")/100) + "
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nFgts+")/100))  as Decimo_Terc, "
			_cquery2 	+= "  		(decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) as Folha, "
			_cquery2 	+= " (SELECT SUM(RC_VALOR) FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND  RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('727','831')) AS VALOR_MULTA_DEMIS,  "
			_cquery2 	+= " (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
			_cquery2 	+= " (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('097')) TM ) AS VALOR_SM, "
			_cquery2 	+= " (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
			_cquery2 	+= " (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('098')) TM ) AS VALOR_ACD_INSS, "
			_cquery2 	+= " (SELECT ((TSM.VALOR*"+_cSMT+")/100) FROM "//52.46336
			_cquery2 	+= " (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('121','323','361')) TSM ) AS VALOR_SMT, "
			_cquery2 	+= " (SELECT TDC.VALOR+((TDC.VALOR*"+_cDC+")/100) FROM "//37,22
			_cquery2 	+= " (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('200','356','205')) TDC ) AS VALOR_DC, "
			
			_cquery2 	+= " (SELECT ((TE.VALOR*"+_cEST+")/100) FROM "//15.241
			_cquery2 	+= " (SELECT SUM(RC_VALOR) VALOR FROM " + RETSQLNAME("SRC") + " SRC WHERE SRC.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RC_FILIAL = '"+_afiliais[_nip]+"' AND RC_PERIODO >= '"+_cDIncial+"' AND  RC_PERIODO <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RC_PD IN ('192','193')) TE ) AS VALOR_ESTAG "
			_cquery2 	+= " from ( "
			_cquery2 	+= "   	select 	sum(RC_valor) as proventos, "
			_cquery2 	+= " 				 	RC_filial  "
			_cquery2 	+= " 		from " + retsqlname("SRC") + " SRC2  join " + retsqlname("SRV") + " SRV2 on rc_filial = rv_filial and rc_pd = rv_cod "
			_cQuery2 += " WHERE RC_FILIAL = '" + _afiliais[_nip] + "'"
			_cquery2 	+= "   	AND	sRC2.d_e_l_e_t_ = ' ' and srv2.d_e_l_e_t_ = ' ' "
			_cquery2	+= "	AND	RV_I_CUSTG = '1' "

			If VV = 1//query com verbas com todos os impostos
			   _cquery2	+= " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' " 				
			ElseIf VV = 2//query com verbas sem impostos
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' " 				
			ElseIf VV = 3//query com verbas FGTS
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' " 				
			EndIf
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf

			_cquery2 	+= " 		group by RC_filial) p "
			_cquery2 	+= " FULL OUTER join ( "
			_cquery2 	+= " 		select sum(RC_valor) as devol, "
			_cquery2 	+= " 				RC_filial "
			_cquery2 	+= " 		from " + retsqlname("SRC") + " SRC3 join " + retsqlname("SRV") + " SRV3 on rc_filial = rv_filial and rc_pd = rv_cod "
			_cquery2 	+= "  WHERE SRC3.D_E_L_E_T_ = ' '  AND SRV3.D_E_L_E_T_ = ' ' " 
			_cQuery2    += "       AND RC_FILIAL = '" + _afiliais[_nip] + "'"
			_cquery2	+= " 	   AND RV_I_CUSTG = '2' "

			If VV = 1//query com verbas com todos os impostos
			   _cquery2	+= " 	   AND RV_INSS = 'S' AND RV_FGTS = 'S' " 				
			ElseIf VV = 2//query com verbas sem impostos
			   _cquery2	+= " 	   AND RV_INSS = 'N' AND RV_FGTS = 'N' "				
			ElseIf VV = 3//query com verbas FGTS
			   _cquery2	+= " 	   AND RV_INSS = 'N' AND RV_FGTS = 'S' "				
			EndIf
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RC_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += " AND RC_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= " 		GROUP BY RC_FILIAL) D "
			_cquery2 	+= " 				ON P.RC_FILIAL = D.RC_FILIAL "
			_cquery2 	+= " ) TMP ) TMP2 "
		Else
			//Total de verbas
			_cquery2 	+= " TMP2.TOTAL_GERAL  AS TOTAL_T  FROM "
			
			If VV = 1//query com verbas com todos os impostos
				_cquery2 	+= " (SELECT "
				_cquery2 	+= "  (SUM(TMP.INSS+TMP.ACT+TMP.RAT_TERC+TMP.FGTS+TMP.FERIAS+TMP.DECIMO_TERC+TMP.FOLHA)+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_ESTAG),NULL,0,SUM(TMP.VALOR_ESTAG))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_MULTA_DEMIS),NULL,0,SUM(TMP.VALOR_MULTA_DEMIS))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_SM),NULL,0,SUM(TMP.VALOR_SM))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_ACD_INSS),NULL,0,SUM(TMP.VALOR_ACD_INSS))+"				
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_DC),NULL,0,SUM(TMP.VALOR_DC))+"
				_cquery2 	+= "  DECODE(SUM(TMP.VALOR_SMT),NULL,0,SUM(TMP.VALOR_SMT))) AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_T
			ElseIf VV = 2//query com verbas sem impostos
				_cquery2 	+= " (SELECT "
				_cquery2 	+= " (SUM(TMP.FOLHA))"
				_cquery2 	+= " AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_SE
			ElseIf VV = 3//query com verbas FGTS
				_cquery2 	+= " (SELECT "
				_cquery2 	+= " (SUM(TMP.FOLHA+TMP.FGTS))"
				_cquery2 	+= " AS TOTAL_GERAL FROM ( "//TOTAL_GERAL_F
			EndIf
			
			_cquery2 	+= " select "
			_cquery2 	+= " 		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nInss+")/100) as INSS,"
			_cquery2 	+= "    	((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nAct +")/100) as ACT,"
			_cquery2 	+= "  		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nTerc+")/100) as RAT_TERC,"
			_cquery2 	+= "  		((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * ("+_nFgts+")/100) as FGTS,"
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) + "
			_cquery2 	+= " 	 	(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nInss+")/100) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nAct +")/100) + " 
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) * ("+_nTerc+")/100) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_cFER+")/100) ) *(("+_nFgts+")/100) )) as Ferias, "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) + "
			_cquery2 	+= "  		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nInss+")/100) + " 
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nAct +")/100) + "
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nTerc+")/100) + "
			_cquery2 	+= " 		(((decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) * (("+_c13S+")/100) ) * ("+_nFgts+")/100))  as Decimo_Terc, "
			_cquery2 	+= "  		(decode(p.proventos,null,0,p.proventos) - (Case when d.devol > 1 then d.devol Else 0 end)) as Folha, "
			_cquery2 	+= " (SELECT SUM(RD_VALOR) FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND  RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf			
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('727','831')) AS VALOR_MULTA_DEMIS,  "
			_cquery2 	+= " (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
			_cquery2 	+= " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += "        AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf			
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += "        AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cquery2  += "        AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('097')) TM ) AS VALOR_SM, "
			_cquery2 	+= " (SELECT ((TM.VALOR*"+_nFgts+")/100) FROM "//8.00
			_cquery2 	+= " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"'  "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf			
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('098')) TM ) AS VALOR_ACD_INSS, "
			_cquery2 	+= " (SELECT ((TSM.VALOR*"+_cSMT+")/100) FROM "//52.46336
			_cquery2 	+= " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf			
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('121','323','361')) TSM ) AS VALOR_SMT, "
			_cquery2 	+= " (SELECT TDC.VALOR+((TDC.VALOR*"+_cDC+")/100) FROM "//37,22
			_cquery2 	+= " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf			
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('200','356','205')) TDC ) AS VALOR_DC, "
			_cquery2 	+= " (SELECT ((TE.VALOR*"+_cEST+")/100) FROM "//15.241
			_cquery2 	+= " (SELECT SUM(RD_VALOR) VALOR FROM " + RETSQLNAME("SRD") + " SRD WHERE SRD.D_E_L_E_T_ = ' '  "
			_cquery2 	+= "         AND RD_FILIAL = '"+_afiliais[_nip]+"' AND RD_DATARQ >= '"+_cDIncial+"' AND  RD_DATARQ <= '"+_cDFinal+"' "
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= "         AND RD_PD IN ('192','193')) TE ) AS VALOR_ESTAG "
			_cquery2 	+= " from ( "
			_cquery2 	+= "   	select 	sum(RD_valor) as proventos, "
			_cquery2 	+= " 				 	RD_filial  "
			_cquery2 	+= " 		from " + retsqlname("SRD") + " SRD2  join " + retsqlname("SRV") + " SRV2 on rd_filial = rv_filial and rd_pd = rv_cod "
			_cQuery2    += " WHERE RD_FILIAL = '" + _afiliais[_nip] + "'"
			_cquery2 	+= " 		and	rd_datarq >= '" + _cDIncial + "' and "
			_cquery2 	+= " 		rd_datarq <= '" + _cDFinal + "' and "
			_cquery2 	+= "   		sRD2.d_e_l_e_t_ = ' ' and srv2.d_e_l_e_t_ = ' ' "
			_cquery2	+= "		AND RV_I_CUSTG = '1' "
			If VV = 1//query com verbas com todos os impostos
			   _cquery2	+= " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' " 				
			ElseIf VV = 2//query com verbas sem impostos
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' "				
			ElseIf VV = 3//query com verbas FGTS
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' "				
			EndIf
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= " 		group by RD_filial) p "
			_cquery2 	+= " FULL OUTER join ( "
			_cquery2 	+= " 		select sum(RD_valor) as devol, "
			_cquery2 	+= " 				RD_filial "
			_cquery2 	+= " 		from " + retsqlname("SRD") + " SRD3 join " + retsqlname("SRV") + " SRV3 on rd_filial = rv_filial and rd_pd = rv_cod "
			_cquery2 	+= " 		where 	sRD3.d_e_l_e_t_ = ' '  and srv3.d_e_l_e_t_ = ' ' and "
			_cQuery2 += "  RD_FILIAL = '" + _afiliais[_nip] + "'"
			_cquery2 	+= "	and rd_datarq >= '" + _cDIncial + "'"
			_cquery2 	+= "	and rd_datarq <= '" + _cDFinal + "'"
			_cquery2	+= " 	AND RV_I_CUSTG = '2' "
			If VV = 1//query com verbas com todos os impostos
			   _cquery2	+= " 	AND RV_INSS = 'S' AND RV_FGTS = 'S' "				
			ElseIf VV = 2//query com verbas sem impostos
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'N' "				
			ElseIf VV = 3//query com verbas FGTS
			   _cquery2	+= " 	AND RV_INSS = 'N' AND RV_FGTS = 'S' "				
			EndIf                                                
			If !Empty(ZL6T->ZL6_CONDIC)
				_cquery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
			EndIf
		    If !Empty(ZL6T->ZL6_CENTRO)		
			    _cquery2 += " AND RD_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
  		    EndIf
		    If !Empty(ZL6T->ZL6_NCENTR)
			   _cQuery2  += " AND RD_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
		    EndIf
			_cquery2 	+= " 		group by RD_filial) d "
			_cquery2 	+= " 				on p.RD_filial = d.RD_filial "
			_cquery2 	+= " ) TMP ) TMP2"
		EndIf
		
		MPSysOpenQuery( _cquery2 , "VALOR1" )
		DBSelectArea("VALOR1")
		DBGoTop()
		_cValores+=_cquery2+CRLF
		
		If !(VALOR1->( Eof() ))
			_nValor+=VALOR1->TOTAL_T
 			_cValores+=_afiliais[_nip]+" / "+StrZero(VV,3)+": "+Str(VALOR1->TOTAL_T,22,7)+CRLF+CRLF
		EndIf
		
		VALOR1->( DBCloseArea() )
	Next
Next

If !Empty(_cFilsemSRX)
   _cFilsemSRX:=LEFT(_cFilsemSRX,Len(_cFilsemSRX)-2)
   If !_lLoop .And. !U_ITMsg("Não foram localizados dados de impostos do mês para RH, Filiais: "+_cFilsemSRX+", Deseja continuar ?","ATENÇÃO",,3,2,2) 
      _lLoop:=.T.
   EndIf
   _cTimeIni:= TIME()//Reinicia o tempo pq o usuario pode demorar para responder
EndIf	                                 	

_cValores+="VALOR TOTAL: "+Str(_nValor,22,7)+CRLF
_cValores+="QUANTIDADE: "+Str(_nQuant,22,7)+CRLF

nHandle := FCreate(_cdir+"VALORES_MAO_DE_OBRA_"+cFilant+"_"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cValores)
FClose(nHandle)

Return {_nValor , _nQuant }

/*
===============================================================================================================================
Programa----------: MEST0097
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de horas extras
Parametros--------: _dinicial - data inicial de analise
					 	_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0097(_dinicial,_dfinal)

Local _cquery2 	:= ""
Local _cTabela 	:= "SRD.RD"
Local _cTabela2 	:= "SRC.RC"
Local _cQuery1	:= ""
Local _cFecham	:= ""

//Buscar data do ultimo fechamento  
_cQuery1 := " Select max(rd_datarq) as ULTF from " + retsqlname("SRD") + " srd "
_cQuery1 += " where srd.d_e_l_e_t_ = ' ' "
_cQuery1 += " and rd_filial = '" + xFilial("SRD") + "'"
_cQuery1 += " and rd_roteir = 'FOL' "

MPSysOpenQuery( _cquery1 ,"SRDU" ) 
DBSelectArea("SRDU")

If !(SRDU->( Eof() ))
	_cFecham := SRDU->ULTF
EndIf		

SRDU->( DBCloseArea() )

_cQuery2 	:= " SELECT "

If ZL6T->ZL6_RCMUL > 0
	_cQuery2 	+= "		   (SUM(RD_VALOR) * " + AllTrim(Str(ZL6T->ZL6_RCMUL)) + ") AS RD_VALOR,"  			
Else
	_cQuery2 	+= "		   (SUM(RD_VALOR)) AS RD_VALOR,"
EndIf	  				
_cQuery2 	+= "			SUM(RD_HORAS) AS RD_HORAS"
_cQuery2 	+= "  FROM "+ RetSqlName("SRD") + " SRD "

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE RD_FILIAL = '" + xFilial("SRD") + "'"
Else
	_cQuery2 += " WHERE RD_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
EndIf

_cQuery2 	+= " AND " + _cTabela + "_DATARQ >= '" + AllTrim(Str(YEAR(_dinicial)))+ StrZero(MONTH(_dinicial),2) + "'"
_cQuery2 	+= " AND " + _cTabela + "_DATARQ <= '" + AllTrim(Str(YEAR(_dfinal))) + StrZero(MONTH(_dfinal),2) + "'"
_cQuery2 	+= " AND " + SubStr(_cTabela,1,4) + "D_E_L_E_T_ = ' '"
			
If !Empty(ZL6T->ZL6_RCPD)
	_cQuery2 += " AND " + _cTabela + "_PD IN " + FormatIn(AllTrim(ZL6T->ZL6_RCPD),";")
EndIf	
		
If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

If !Empty(ZL6T->ZL6_NCENTR)
   _cQuery2  += " AND "+ _cTabela + "_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
EndIf

If !Empty(ZL6T->ZL6_CENTRO)
   _cQuery2  += " AND "+ _cTabela + "_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
EndIf

// Se faixa de data dos parâmetros pertence pelo menos um dia à competência do MV_FOLMES puxa o SRC inteiro
// para o resultado pois o RC_PERIODO pode conter datas fora do período mas ainda assim pertencer a competência do MV_FOLMES]
If (StrZero(YEAR(MV_PAR05),4) + StrZero(MONTH(MV_PAR05),2)) > _cFecham;
	.Or. (StrZero(YEAR(MV_PAR06),4) + StrZero(MONTH(MV_PAR06),2)) > _cFecham
	_cQuery2 += " UNION ALL"
	_cQuery2 	+= " SELECT "

	If ZL6T->ZL6_RCMUL > 0 
		_cQuery2 	+= "		   (SUM(RC_VALOR) * " + AllTrim(Str(ZL6T->ZL6_RCMUL)) + ") AS RD_VALOR,"
	Else
		_cQuery2 	+= "		   (SUM(RC_VALOR)) AS RD_VALOR,"
	EndIf
	_cQuery2 	+= "			SUM(RC_HORAS) AS RD_HORAS" 			
	_cQuery2 	+= "  FROM "+ RetSqlName("SRC") + " SRC "
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " WHERE RC_FILIAL = '" + xFilial("SRC") + "'"
	Else
		_cQuery2 += " WHERE RC_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";") 
	EndIf
	_cQuery2 	+= " AND " + SubStr(_cTabela2,1,4) + "D_E_L_E_T_ = ' '"
			
	If !Empty(ZL6T->ZL6_RCPD)
		_cQuery2 += " AND " + _cTabela2 + "_PD IN " + FormatIn(AllTrim(ZL6T->ZL6_RCPD),";")
	EndIf	
		
	If !Empty(ZL6T->ZL6_CONDIC)
		_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
	EndIf
	
	If !Empty(ZL6T->ZL6_NCENTR)
   		_cQuery2  += " AND "+ _cTabela2 + "_CC NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCENTR),";")
	EndIf

	If !Empty(ZL6T->ZL6_CENTRO)
   		_cQuery2  += " AND "+ _cTabela2 + "_CC IN " + FormatIn(AllTrim(ZL6T->ZL6_CENTRO),";")
	EndIf
EndIf

Return _cquery2  

/*
===============================================================================================================================
Programa----------: MEST0098
Autor-------------: Josue Danich
Data da Criacao---: 29/10/2015
Descricao---------: Retorna query para custo gerencial de saldos iniciais
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0098(_dinicial,_dfinal)

Local _cQuery2 	:= ""
Local _cTabela 	:= "SB9.B9"
Local _nmes		:= 0
Local _nano		:= 0
Local _dquery

//Calcula data do B9 para saldos iniciais
_nmes 		:= month(_dinicial)
_nano		:= year(_dinicial)
_dquery		:= SToD(StrZero(_nano,4)+StrZero(_nmes,2)+'01')
_dquery 	:= _dquery - 1	

_cQuery2 	:= " SELECT "
_cQuery2 	+= "  			B9_COD,"
_cQuery2 	+= "  			B9_LOCAL,"
If ZL6T->ZL6_TUNID == 'S'
	_cQuery2	+= " 			B9_QISEGUM B9_QINI,"
Else
	_cQuery2	+= " 			B9_QINI,"
EndIf
_cQuery2 	+= "  			B9_VINI1,"
_cQuery2 	+= "  			B9_DATA,"
_cQuery2 	+= "  			B9_FILIAL "
_cQuery2 	+= "  FROM " + RetSqlName("SB9") + " SB9"		

If Empty(ZL6T->ZL6_FILIS)
	_cQuery2 += " WHERE B9_FILIAL = '" + xFilial("SB9") + "'"
Else
	_cQuery2 += " WHERE B9_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
EndIf

_cQuery2 	+= " AND " + _cTabela + "_DATA = '" + DToS(_dquery) + "'"

If  AllTrim(ZL6T->ZL6_TPCUS) == '000004'
	_cquery2 	+= " AND B9_LOCAL IN ( SELECT NNR_CODIGO FROM " + RetSqlName("NNR") + " NNR WHERE "
	_cquery2 	+= "													      			NNR.NNR_CODIGO NOT IN ('40','36','37') AND "
	_cquery2 	+= "													      			NNR.D_E_L_E_T_ = ' ' AND "
	_cquery2 	+= "													      			NNR.NNR_FILIAL = '" + xFilial("NNR")+"') "
Else
	_cquery2 	+= " AND ( SELECT NNR_I_PA FROM " + RetSqlName("NNR") + " NNR WHERE 	NNR.NNR_CODIGO NOT IN ('40','36','37') AND "
	_cquery2 	+= "													      			NNR.NNR_CODIGO = SB9.B9_LOCAL AND"
	_cquery2 	+= "													      			NNR.D_E_L_E_T_ = ' ' AND "
	_cquery2 	+= "													      			NNR.NNR_FILIAL = '" + xFilial("NNR") + "' AND "
	_cquery2 	+= "													      			ROWNUM = 1) = '1'"
EndIf
	
If  !Empty(ZL6T->ZL6_TPROD)
	_cQuery2 += " AND (SELECT B1_TIPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "'"
	_cQuery2 += "                                                      AND D_E_L_E_T_ = ' '"
	_cQuery2 += "                                                      AND SB1.B1_COD = SB9.B9_COD ) "
	_cQuery2 += " IN " + FormatIn(AllTrim(ZL6T->ZL6_TPROD),";")
EndIf

If  !Empty(ZL6T->ZL6_NTPRO)
	_cQuery2 += " AND (SELECT B1_TIPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "'"
	_cQuery2 += "                                                      AND D_E_L_E_T_ = ' '"
	_cQuery2 += "                                                      AND SB1.B1_COD = SB9.B9_COD ) "
	_cQuery2 += " NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NTPRO),";")
EndIf

If	!Empty(ZL6T->ZL6_CODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD IN " + FormatIn(AllTrim(ZL6T->ZL6_CODPRO),";")
EndIf

If !Empty(ZL6T->ZL6_NCODPRO)
	_cQuery2 += " AND " + _cTabela + "_COD NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NCODPRO),";")
EndIf	

If	!Empty(ZL6T->ZL6_GRPPRO)
	_cQuery2 += " AND (SELECT B1_GRUPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "'"
	_cQuery2 += "                                                      AND D_E_L_E_T_ = ' '"
	_cQuery2 += "                                                      AND SB1.B1_COD = SB9.B9_COD ) "
	_cQuery2 += " IN " + FormatIn(AllTrim(ZL6T->ZL6_GRPPRO),";")
EndIf

If	!Empty(ZL6T->ZL6_NGRPPR)
	_cQuery2 += " AND (SELECT B1_GRUPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "'"
	_cQuery2 += "                                                      AND D_E_L_E_T_ = ' '"
	_cQuery2 += "                                                      AND SB1.B1_COD = SB9.B9_COD ) "
	_cQuery2 += " NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NGRPPR),";")
EndIf

If !Empty(ZL6T->ZL6_CONDIC)
	_cQuery2 += " AND "+StrTran(Upper(AllTrim(ZL6T->ZL6_CONDIC)),"SIGA.","")
EndIf

_cQuery2 	+= " AND " + SubStr(_cTabela,1,4) + "D_E_L_E_T_ = ' '"
_cQuery2 += " ORDER BY " + _cTabela + "_COD" 

Return _cquery2 

/*
===============================================================================================================================
Programa----------: MEST0099
Autor-------------: Josue Danich
Data da Criacao---: 16/12/2015
Descricao---------: Retorna query para custo gerencial de gestao do leite
Parametros--------: _dinicial - data inicial de analise
					_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST0099(_dinicial,_dfinal)

Local _cquery2 	:= ""

If ZL6T->ZL6_TERCEI = "S"
	_cquery2 += " SELECT SUM(ZLX_VOLREC) AS QUANT , 0 AS CREDITO, 0 AS DEBITO FROM " + RetSqlName("ZLX") + " ZLX "
	_cquery2 += " WHERE D_E_L_E_T_ = ' '
	If Empty(ZL6T->ZL6_FILIS)
		_cquery2 += " AND ZLX.ZLX_FILIAL = '" + xFilial("ZLX") + "'"
	Else
		_cquery2 += " AND ZLX.ZLX_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf
	_cquery2 += " AND ZLX_TIPOLT = 'T' "
	_cquery2 += " AND ZLX_DTENTR BETWEEN '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
Else
	_cquery2 += " SELECT ZLF.ZLF_LINROT ZLD_LINROT,ZLF.ZLF_A2COD ,ZLF.ZLF_A2LOJA,
	_cquery2 += "		SUM(ZLF_QTDBOM) AS QUANT,"
	_cquery2 += " 	SUM( Case WHEN ZLF_DEBCRE = 'C' THEN ZLF_TOTAL Else 0 END ) as CREDITO,"
	_cquery2 += " 	SUM( Case WHEN ZLF_DEBCRE = 'D' THEN ZLF_TOTAL Else 0 END ) as DEBITO	 "
	_cquery2 += " FROM " + RetSqlName("ZLF") + " ZLF "
	_cquery2 += " JOIN " + RetSqlName("SA2") + " SA2 ON SA2.A2_COD = ZLF.ZLF_A2COD AND SA2.A2_LOJA = ZLF.ZLF_A2LOJA "
	_cquery2 += " WHERE ZLF.D_E_L_E_T_ = ' ' "
	_cquery2 += " AND SA2.D_E_L_E_T_ = ' ' "
	
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery2 += " AND ZLF.ZLF_FILIAL = '" + xFilial("ZLF") + "'"
	Else
		_cQuery2 += " AND ZLF.ZLF_FILIAL IN " + FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf
	
	_cquery2 += " AND SubStr(ZLF.ZLF_A2COD,1,1) = 'P' "
	
	If !Empty(ZL6T->ZL6_FORNEC)
		_cQuery2 += " AND ZLF.ZLF_A2COD IN " + FormatIn(AllTrim(ZL6T->ZL6_FORNEC),";")
	EndIf
	
	If !Empty(ZL6T->ZL6_NFORNE)
		_cQuery2 += " AND ZLF.ZLF_A2COD NOT IN " + FormatIn(AllTrim(ZL6T->ZL6_NFORNE),";")
	EndIf
	
	If !Empty(ZL6T->ZL6_SETOR)
		_cQuery2 += " AND ZLF.ZLF_SETOR IN " + FormatIn(AllTrim(ZL6T->ZL6_SETOR),";")
	EndIf
	
	If !Empty(ZL6T->ZL6_EVENTO)
		_cQuery2 += " AND ZLF.ZLF_EVENTO IN " + FormatIn(AllTrim(ZL6T->ZL6_EVENTO),";")
	EndIf
	
	If !Empty(ZL6T->ZL6_CODMIX)
		_cQuery2 += " AND ZLF.ZLF_CODZLE IN " + FormatIn(AllTrim(ZL6T->ZL6_CODMIX),";")
	EndIf

	_cquery2 += " AND ZLF.ZLF_DTINI BETWEEN '" + DToS(_dinicial) + "' AND '"+ DToS(_dfinal) +"' "
	_cquery2 += " AND ZLF.ZLF_DTFIM BETWEEN '" + DToS(_dinicial) + "' AND '"+ DToS(_dfinal) +"' "
	_cquery2 += " GROUP BY ZLF.ZLF_LINROT,ZLF.ZLF_A2COD,ZLF.ZLF_A2LOJA "
	_cquery2 += " ORDER BY 1,2,3 "
EndIf

Return _cquery2 


/*
===============================================================================================================================
Programa----------: MEST009A
Autor-------------: Josue Danich
Data da Criacao---: 02/03/2016
Descricao---------: Retorna query para frete proporcional
Parametros--------: _dinicial - data inicial de analise
						_dfinal   - data final e analise
Retorno-----------: _cquery2  - query a ser executada
===============================================================================================================================
*/ 
User Function MEST009A(_dinicial,_dfinal,_cCF,_cProd,_cCC)

Local _cQuery2 := ""
Local _nValor  := _nQtde:=0

Default _cCF  :='RE1'
Default _cProd:=AllTrim(ZL6T->ZL6_CODPRO)
Default _cCC  :=AllTrim(ZL6T->ZL6_CENTRO)

_cQuery2:= " SELECT SUM(D3_QUANT) QUANT "
_cQuery2+= "  FROM " + RetSqlName("SD3") + " SD3 "
_cQuery2+= " WHERE SD3.D3_FILIAL = '" + xFilial("SD3") + "'"
_cQuery2+= " AND SD3.D3_EMISSAO BETWEEN '" + DToS(_dinicial) + "' AND '" + DToS(_dfinal) + "'"
_cQuery2+= " AND SD3.D3_ESTORNO <> 'S' "
_cQuery2+= " AND SD3.D3_CF = '"+_cCF+"' "
_cQuery2+= " AND SD3.D_E_L_E_T_ = ' '"
If !Empty(_cCC)
   _cQuery2 += " AND SD3.D3_CC IN " + FormatIn(_cCC,";")
EndIf
_cQuery:=_cQuery2

If !Empty(_cProd)
   _cQuery2 += " AND SD3.D3_COD IN " + FormatIn(_cProd,";")
   _cQuery:=_cQuery2
   MPSysOpenQuery( _cQuery2 ,"SD2T" ) 

   If .NOT. SD2T->( Eof() )
      _nQtde:=SD2T->QUANT
   EndIf
EndIf

Return {_nValor,_nQtde}

/*
===============================================================================================================================
Programa----------: MEST009N
Autor-------------: Josue Danich
Data da Criacao---: 30/10/2015
Descricao---------: Valida edicao dos campos ZL6 com base no ZL6_OBSERV
Parametros--------: _cCond - Quais origens de informacao que permitem a edicao do campo
Retorno-----------: .T. se e campo editavel ou .F. se e campo bloqueado
===============================================================================================================================
*/
User Function MEST009N(_cCond)

Return .T.

/*
===============================================================================================================================
Programa----------: MEST009Y
Autor-------------: Josue Danich Prestes
Data da Criacao---: 04/11/2015
Descricao---------: Gera Excel de custos gerenciais
Parametros--------: _oself , _nRegZL6
Retorno-----------:
===============================================================================================================================
*/
Static Function MEST009Y(_oself,_nRegZL6,_lEnd)

Local _axmlc	:= {}
Local _axmld	:= {}
Local _axmle	:= {}
Local _axmlf	:= {}
Local _cFile01 	:= "Custos01.xml"
Local _cFile02	:= "Custos02.xml"
Local _cFile03	:= "Custos03.xml"
Local _cFile04	:= "Custos04.xml"
Local _nH		:= 0 
Local _nI 		:= 1
Local _aze0		:= {}
Local _aze1		:= {}
Local _azeNew	:= {}
Local _nvalope 	:= 0
Local _np		:= 0
Local _nConta   := 0 , _ni2 , _cTotReg  
Default _lEnd:=.F.

//Planilha 01-Operacional - PA,  Grupos (000001/000002/000003)
//Planilha 02-Custo / Estoque - MP,  Grupos (000004/000005)   
//Planilha 03-Demonstrativo do Estoque Final,  Grupo (000006) 
//Planilha 04-Espelho Composicao dos Custos,  Depende do 01   

Private _lGera1Pla:= (Empty(MV_PAR12) .Or. "01" $ MV_PAR12) .And. (Empty(MV_PAR01) .Or. '000001' $ AllTrim(MV_PAR01) .Or. '000002' $ AllTrim(MV_PAR01) .Or. '000003' $ AllTrim(MV_PAR01) )//Planilha 01 *
Private _lGera2Pla:= (Empty(MV_PAR12) .Or. "02" $ MV_PAR12) .And. (Empty(MV_PAR01) .Or. '000004' $ AllTrim(MV_PAR01) .Or. '000005' $ AllTrim(MV_PAR01)) .And. _lGera1Pla//Planilha 02 com 2 pastas e Le a palnilha 1
Private _lGera3Pla:= (Empty(MV_PAR12) .Or. "03" $ MV_PAR12) .And. (Empty(MV_PAR01) .Or. '000006' $ AllTrim(MV_PAR01))               //Planilha 03 
Private _lGera4Pla:= (Empty(MV_PAR12) .Or. "04" $ MV_PAR12) .And. _lGera1Pla .And. _lGera1Pla                                       //Planilha 04 e Le a palnilha 1 e 2 

If !_lGera1Pla .And. !_lGera2Pla .And. !_lGera3Pla .And. !_lGera4Pla //.AND. !_lGera5Pla .And. !_lGera6Pla .And. !_lGera7Pla .And. !_lGera8Pla .And. !_lGera9Pla .And. !_lGeraAPla
   U_ITMsg("Nenhuma Planilha será gerada devido a combinação dos parametros",'Atenção!',"Verifique os parametros e tente novamente",1)
   Return .F.
EndIf

Private _lGerouAlguma:=.F.
Private _nPag	 := 1
Private _aCusto04:={}

//Roda SubEngine que prepara arrays e valores de gravação
MEST009SE( _nRegZL6, _oself, @_aze0, @_aze1, @_nvalope, @_azeNew,@_lEnd)
If _lLoop
   Return .F.
EndIf

//CRIANDO PLANILHA 1
If _lGera1Pla
	Begin Sequence 

	If FILE(_cdir+_cFile01)
		_nConta :=1
		While FERASE(_cdir+_cFile01) = -1 .And. _nConta <= 5
			U_ITMsg("FECHE A PLANILHA: "+_cdir+_cFile01,'Atenção! '+AllTrim(Str(_nConta))+" tentativas de 5","Para o sistema consegui-la gera-lá novamente",3)
			_nConta++
		EndDo

		If FILE(_cdir+_cFile01) .And. FERASE(_cdir+_cFile01) = -1
			U_ITMsg("A PLANILHA: "+_cdir+_cFile01+" não pode ser gerada",'Atenção!',"Não foi possivel apagar o arquivo "+_cdir+_cFile01,1)
			Break
		EndIf
	EndIf
	
	//Monta cabecalho do excel - 01-Operacional - PA
	_axmlc := MEST009E1()
    If Len(_axmlc) = 0
	   Break
    EndIf

	If _lGera4Pla .Or. _lGera2Pla //.OR. _lGera1Pla
  	   _aCusto04:={}
	    aAdd(_aCusto04,{"CUSTO OPERACIONAL                 ",00,0,0})//01
		aAdd(_aCusto04,{"CUSTO OPERACIONAL FILIAIS         ",00,0,0})//02
		aAdd(_aCusto04,{"CUSTO LEITE IN-NATURA + FRETE     ",00,0,0})//03
		aAdd(_aCusto04,{"CUSTO SORO DE LEITE + FRETE       ",00,0,0})//04
		aAdd(_aCusto04,{"CUSTO SORO CONCENTRADO + FRETE    ",00,0,0})//05    
		aAdd(_aCusto04,{"CUSTO CREME DE LEITE + FRETE      ",00,0,0})//06     
	    aAdd(_aCusto04,{"CUSTO SORO PRE-CONCENTRADO + FRETE",00,0,0})//07 *** NOVO
		aAdd(_aCusto04,{"CUSTO COM ICMS P/ LEITE UHT       ",00,0,0})//08
		aAdd(_aCusto04,{"CUSTO COM ICMS P/ DERIVADOS       ",00,0,0})//09
		aAdd(_aCusto04,{"CUSTO COM ICMS P/ MERC. ADQUIRIDAS",00,0,0})//10
		aAdd(_aCusto04,{"CUSTO IRPJ/CSSL(PARCELAMENTO)     ",00,0,0})//11
    EndIf	

	//Monta corpo da página de custo operacional do excel - 01-Operacional - PA
	If Len(_aze0) > 0
		_axmld := MEST009E2(_aze0,"CUSTO OPERACIONAL",_ntotlei)
		_nPag++
	EndIf
	
	//Monta corpo das páginas de custo de produtos acabados do excel - 01-Operacional - PA
	_axmlt := {}
	_aze2  := {}
	
	_oself:SetRegua1( Len(_aze1) )
	_oself:SetRegua2( Len(_aze1) )
	_cTotReg:=AllTrim(Str( Len(_aze1) ))
	_nConta :=0
	For _nI := 1 To Len(_aze1)
		_nConta++
	    If ValType(_oSelf) = "O" 
		   _oself:IncRegua1("8-Processando Regras "+Str(_nConta,6)+" de "+_cTotReg )
  	       _oself:IncRegua2(AllTrim(_aze1[_nI][09]))
           ProcessMessages()
	       If _lEnd 
              If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
                 _lLoop:=.T.
                 Return .F.
              EndIf   
	       EndIf
        EndIf   
		If _nI = Len(_aze1) .Or. _aze1[_nI][08] != _aze1[_nI + 1][08]
			If !(_aze1[_nI][13] == "4")//ZL6_REGRA
				aAdd( _aze2, {	_aze1[_nI][01],;										//01
				_aze1[_nI][02],;														//02
				_aze1[_nI][03],;														//03
				_aze1[_nI][06],;														//04
				_aze1[_nI][07],;														//05
				_aze1[_nI][06],;														//06
				_aze1[_nI][07],;														//07
				_aze1[_nI][04],;														//08
				_aze1[_nI][05],;														//09
				_aze1[_nI][10],;														//10
				_aze1[_nI][11],;														//11
				_aze1[_nI][12],;														//12
				_aze1[_nI][13],;														//13
				_aze1[_nI][14],;														//14
				_aze1[_nI][15],;														//15
				_aze1[_nI][09],;														//16
				_aze1[_nI][08],;														//17
				_aze1[_nI][21],;														//18 ZL6_CUSPR
				_aze1[_nI][26],;														//19 ZL6_REDIME
				_aze1[_nI][20],;														//20 ZL6_OBSERV
				_aze1[_nI][27]})														//21 _nQtdemKG
			EndIf
			
			_np := aScan(_atotlei,{|_vAux|_vAux[1]==_aze1[_nI][08]})
			If Len(_aze2) > 0
				If _np > 0
					_axmlt := MEST009E2(_aze2,"PRODUTOS ACABADOS - " + _aze1[_nI][09],_atotlei[_np][2],,_atotlei[_np][4])
				Else
					_axmlt := MEST009E2(_aze2,"PRODUTOS ACABADOS - " + _aze1[_nI][09],0)
				EndIf
			EndIf
			
			_nPag++
			
			For _ni2 := 1 To Len(_axmlt)
				aAdd(_axmlf, _axmlt[_ni2])
			Next
			_axmlt := {}
			_aze2 := {}
		Else
			If !(_aze1[_nI][13] == "4")//ZL6_REGRA
				aAdd( _aze2, {	_aze1[_nI][01],;										//01
				_aze1[_nI][02],;														//02
				_aze1[_nI][03],;														//03
				_aze1[_nI][06],;														//04
				_aze1[_nI][07],;														//05
				_aze1[_nI][06],;														//06
				_aze1[_nI][07],;														//07
				_aze1[_nI][04],;														//08
				_aze1[_nI][05],;														//09
				_aze1[_nI][10],;														//10
				_aze1[_nI][11],;														//11
				_aze1[_nI][12],;														//12
				_aze1[_nI][13],;														//13
				_aze1[_nI][14],;														//14
				_aze1[_nI][15],;														//15
				_aze1[_nI][09],;														//16
				_aze1[_nI][08],;														//17
				_aze1[_nI][21],; 														//18 ZL6_CUSPR
				_aze1[_nI][26],;														//19 ZL6_REDIME
				_aze1[_nI][20],;														//20 ZL6_OBSERV
				_aze1[_nI][27]})														//21 _nQtdemKG
			EndIf
		EndIf
	Next
	
	_oself:IncRegua2("OK")
	
	//Monta totais e final do excel - 01-Operacional - PA
	_axmle := MEST009E3()//Finaliza arquivo Excel
	
	//CRIANDO PLANILHA 1 - 01-Operacional - PA
	_nH := FCreate(_cdir+_cFile01)
	
	If _nH == -1
	   U_ITMsg("Falha ao criar arquivo: "+_cdir+_cFile01+" / ERRO "+Str(FERROR()),"ATENÇÃO","Tente novamente",1)
	   Break
	EndIf
	
	_oself:SetRegua1( (Len(_axmlc)/100)+10 )
	_cTotReg:=AllTrim(Str( Len(_axmlc) ))
	_nConta :=0
	
	For _nI := 1 To Len(_axmlc)//CABECALHO DO EXCEL DA PLANILHA 1 - 01-Operacional - PA
		_nConta++
	    If ValType(_oSelf) = "O" .And. (MOD(_nConta,100) = 0 .Or. _nConta < 10)
		   _oself:IncRegua1("1/4-Gerando "+_cFile01+Str(_nConta,7)+" de "+_cTotReg )
		EndIf   
		
  		FWrite(_nH,_axmlc[_nI] + CRLF )
	Next
	
	_oself:SetRegua1( (Len(_axmld)/100)+10 )
	_cTotReg:=AllTrim(Str( Len(_axmld) ))
	_nConta :=0
	
	For _nI := 1 To Len(_axmld)//PLANILHA 1 - 01-Operacional - PA
		_nConta++
	    If ValType(_oSelf) = "O" .And. (MOD(_nConta,100) = 0 .Or. _nConta < 10)
		   _oself:IncRegua1("2/4-Gerando "+_cFile01+Str(_nConta,7)+" de "+_cTotReg )
		EndIf   
		
  		FWrite(_nH,_axmld[_nI] + CRLF )
	Next
	
	_oself:SetRegua1( (Len(_axmlf)/100)+10 )
	_cTotReg:=AllTrim(Str( Len(_axmlf) ))
	_nConta :=0
	
	For _nI := 1 To Len(_axmlf)//PLANILHA 1 - 01-Operacional - PA
		_nConta++
	    If ValType(_oSelf) = "O" .And. (MOD(_nConta,100) = 0 .Or. _nConta < 10)
		   _oself:IncRegua1("3/4-Gerando "+_cFile01+Str(_nConta,7)+" de "+_cTotReg )
		EndIf   
		
  		FWrite(_nH,_axmlf[_nI] + CRLF )
	Next
	
	_oself:SetRegua1( (Len(_axmle)/100)+10 )
	_cTotReg:=AllTrim(Str( Len(_axmle) ))
	_nConta :=0
	
	For _nI := 1 To Len(_axmle)//PLANILHA Custos01.xml - 01-Operacional - PA
		_nConta++
	    If ValType(_oSelf) = "O" .And. MOD(_nConta,100) = 0
		   _oself:IncRegua1("4/4-Gerando "+_cFile01+Str(_nConta,7)+" de "+_cTotReg )
		EndIf   
		
  		FWrite(_nH,_axmle[_nI] + CRLF )
	Next
	
	_oself:IncRegua1("ABRINDO PLANILHA 1, AGUARDE..." )
	
	FClose(_nH)

    If _lEnd 
       If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
          _lLoop:=.T.
          _lGerouAlguma:=.F.
        EndIf   
	EndIf

	If !lHtml
	   If !_lEnd .And. ShellExecute("open", _cFile01, "", _cdir, 1) > 41 // ABRE PLANILHA Custos01.xml - 01-Operacional - PA
          _lGerouAlguma:=.T.
       EndIf   
	ElseIf !_lEnd
	   If (nErro:=CpyS2TW(_cdir+_cFile01)) <> 0
		  U_ITMsg("Falha ao abrir arquivo: "+_cdir+_cFile01+" / ERRO "+Str(nErro),"ATENÇÃO","Tente novamente",1)
	   Else
          _lGerouAlguma:=.T.
	   EndIf
	EndIf
   End Sequence
EndIf

_nContPlan:=0
_nContTPlan:=0
If(_lGera2Pla,_nContTPlan++,)
If(_lGera3Pla,_nContTPlan++,)
If(_lGera4Pla,_nContTPlan++,)   

If !_lEnd .And. _lGera2Pla//02-Custo MP/ Estoque - MP - Rodas os codigos '000004' e '000005' 
   _nContPlan++
   MEST9ProcPlan(_cFile02 , {|| MEST92Plan(_azeNew)   }, _oself,@_lEnd ) //GERA A PLANILHA Custos02.xml
EndIf

If !_lEnd .And. _lGera3Pla//03-Demonstrativo do Estoque Final - Rodas os codigos '000006' 
   _nContPlan++
   MEST9ProcPlan(_cFile03 , {|| MEST93Plan(_azeNew)   }, _oself,@_lEnd ) //GERA A PLANILHA Custos03.xml
EndIf

If !_lEnd .And. _lGera4Pla//04-Espelho Composicao dos Custos - depende da palnilha 01
   _nContPlan++
   MEST9ProcPlan(_cFile04 , {|| MEST94Plan(_aCusto04) }, _oself,@_lEnd ) //GERA A PLANILHA Custos04.xml
EndIf

U_ITLOGACS('MEST009')

Return _lGerouAlguma

/*
===============================================================================================================================
Programa----------: MEST9ProcPlan()
Autor-------------: Alex Wallauer
Data da Criacao---: 27/07/2018
Descricao---------: Testa, gera e abre as novas planilhas
Parametros--------: _cFile,_bExecuta,_oself
===============================================================================================================================
*/
Static Function MEST9ProcPlan(_cFile,_bExecuta,_oSelf,_lEnd)

Local _nFile,_aXmlNovo,_cTotReg , _nI
Local _nConta:=1

Private _oRegua:=_oSelf

Default _lEnd:=.F.

If !totvs.framework.environment.Type.get() == '1' //1-Produção, 2-Homologação,3-Desenvolvimento
   _cFile:="D"+_cFile
EndIf

Begin Sequence
    If FILE(_cdir+_cFile)
	   While FERASE(_cdir+_cFile) = -1 .And. _nConta <= 5
	   	  U_ITMsg("FECHE A PLANILHA: "+_cdir+_cFile,'Atenção! '+AllTrim(Str(_nConta))+" tentativas de 5","Para o sistema consegui-la gera-lá novamente",3)
		  _nConta++
	   EndDo
	
	   If FILE(_cdir+_cFile) .And. FERASE(_cdir+_cFile) = -1
		  U_ITMsg("A PLANILHA: "+_cdir+_cFile+" não pode ser gerada",'Atenção!',"Não foi possivel apagar o arquivo "+_cdir+_cFile,1)
		  Break
	   EndIf
    EndIf

	_nFile := FCreate(_cdir+_cFile)
	
	If _nFile == -1
		U_ITMsg("Falha ao criar arquivo: "+_cdir+_cFile+" / ERRO "+Str(FERROR()),"ATENÇÃO","Tente novamente",1)
		Break
	EndIf
	_oself:IncRegua1("Lendo dados da PLANILHA "+_cFile)
	_oself:IncRegua2("Aguarde..." )
	_aXmlNovo := EVAL(_bExecuta)//MEST9?Plan(_azeNew) ///GERA A PLANILHA

	If Len(_aXmlNovo) = 0
		Break
	EndIf
	
	_oself:SetRegua1( (Len(_aXmlNovo)/100)+10 )
	_cTotReg:=AllTrim(Str( Len(_aXmlNovo) ))
	_nConta :=0
	
	For _nI := 1 To Len(_aXmlNovo)
		_nConta++
	    If ValType(_oSelf) = "O" .And. (MOD(_nConta,100) = 0 .Or. _nConta < 10)
		   _oself:IncRegua1(Str(_nContPlan,1)+"/"+Str(_nContTPlan,1)+"-Gerando "+_cFile+Str(_nConta,7)+" de "+_cTotReg )
		EndIf
  		FWrite(_nFile,_aXmlNovo[_nI] + CRLF )

	    If _lEnd 
           If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
              _lLoop:=.T.
              _lGerouAlguma:=.F.
              Exit
           EndIf   
	    EndIf
	Next
	
	_oself:IncRegua1("ABRINDO PLANILHA "+_cFile)
	_oself:IncRegua2("Aguarde..." )
	
	FClose(_nFile)
	
	If !lHtml
		If !_lEnd .And. ShellExecute("open", _cFile, "", _cdir, 1) > 41// ABRE PLANILHA
			_lGerouAlguma:=.T.
		EndIf
	ElseIf !_lEnd
		If (nErro:=CpyS2TW(_cdir+_cFile)) <> 0
			U_ITMsg("Falha ao abrir arquivo: "+_cdir+_cFile+" / ERRO "+Str(nErro),"ATENÇÃO","Tente novamente",1)
		Else
			_lGerouAlguma:=.T.
		EndIf
	EndIf   

End Sequence

Return _lGerouAlguma

/*
===============================================================================================================================
Programa----------: MEST009SE
Autor-------------: Josue Danich Prestes
Data da Criacao---: 06/01/2016
Descricao---------: Subengine de preparação de arrays para excel e banco de dados
Parametros--------: _nRegZL6, _oself, _aze0, _aze1,  _nvalope, _azeNew
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST009SE( _nRegZL6, _oself, _aze0, _aze1,  _nvalope, _azeNew,_lEnd)

Local _aretorno 	:= {}
Local _nQtdSin	:= 0
Local _nVlrSin	:= 0
Local _cordem		:= ""
Local _nI			:= 0
Local _np			:= 0
Local _nContaZ      := 0 , _cTotRegZL6 , _nAux

Private _lTemMateriaPrima:=.F.//Variavel alterada na função _aretorno := U_MEST009E(MV_PAR01,MV_PAR02,MV_PAR05,MV_PAR06,2,_oself,@_lEnd)

//Monta matriz com dados de trabalho
_nRegZL6:=0
DBSelectArea("ZL6T")
COUNT To _nRegZL6
DBGoTop()
_oself:SetRegua1( _nRegZL6 )
_oself:SetRegua2( _nRegZL6 )
_cTotRegZL6:=AllTrim(Str(_nRegZL6))

While ZL6T->(!Eof())
	
	//Roda engine de dados de custo gerencial
	//MV_PAR01 - Tipo Grupo
	//MV_PAR02 - Grupo Custo
	//MV_PAR05 - Data inicial
	//MV_PAR06 - Data Final
	// Ultimo parâmetro indica que e a segunda etapa de leitura de varias tabelas com regras da ZL6 lida na primeira etapa  ZL6_DSUBEV
	_nContaZ++
    If ValType(_oSelf) = "O" 
		_oself:IncRegua1("1-Lendo Regra: "+AllTrim(Str(_nContaZ,6))+" de "+_cTotRegZL6)
		_oself:IncRegua2(ZL6T->ZL6_OBSERV+" - "+AllTrim(ZL6T->ZL6_DSUBEV))
		ProcessMessages()
		If _lEnd 
			If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
				_lLoop:=.T.
				Return .F.
			EndIf   
		EndIf
	EndIf
    	
	_aretorno := U_MEST009E(MV_PAR01,MV_PAR02,MV_PAR05,MV_PAR06,2,_oself,@_lEnd)
    If _lLoop
    	Return .F.
    EndIf
	
	_nQtdSin:= _aretorno[1]
	_nVlrSin:= _aretorno[2]
    If Len(_aretorno) > 2
		_lTemEstoquenaDT:= _aretorno[3]
	Else
		_lTemEstoquenaDT:= .F.
	EndIf
    If Len(_aretorno) > 3
		_aProdutos:= _aretorno[4]
	Else
		_aProdutos:= {}
	EndIf
    If Len(_aretorno) > 4
		_nQtdemKG:=_aretorno[5]
	Else
		_nQtdemKG:=0
	EndIf   
	
	If ZL6T->ZL6_ORDEM > 0
		_cordem :=  AllTrim(StrZero(10000-ZL6T->ZL6_ORDEM,4))
	Else
		_cordem := '00000'
	EndIf

	If AllTrim(ZL6T->ZL6_TPCUS) == '000001' .Or. AllTrim(ZL6T->ZL6_TPCUS) == '000003'  // Tipo de custo operacional 
		aAdd( _aze0, {	xFilial("ZE0"),;															//01
					AllTrim(ZL6T->ZL6_TPCUS),;														//02
					AllTrim(ZL6T->ZL6_DTPCUS),;														//03
					AllTrim(ZL6T->ZL6_CODEVE),;														//04	
					AllTrim(ZL6T->ZL6_DESEVE),;														//05
					AllTrim(ZL6T->ZL6_SUBEVE),;														//06
					AllTrim(ZL6T->ZL6_DSUBEV),;														//07
					AllTrim(ZL6T->ZL6_GRPCUS),;														//08
					AllTrim(ZL6T->ZL6_DGRCUS),;														//09
					_nQtdSin,;																		//10
					_nVlrSin,;																		//11
					(SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4)),;					//12
					AllTrim(ZL6T->ZL6_REGRA),;														//13
					_cordem,;																		//14
					AllTrim(ZL6T->ZL6_CODPRO),;														//15
					ZL6T->ZL6_TCUSTO,;																//16
					ZL6T->ZL6_TUNID,;																//17
					ZL6T->ZL6_CODPRO,;                                                              //18
					ZL6T->ZL6_CENTRO,; 																//19				
					ZL6T->ZL6_OBSERV,; 																//20  ZL6T->ZL6_FILIS
					0})																				//21 
	ElseIf AllTrim(ZL6T->ZL6_TPCUS) == '000002'  // Tipo de custo produto acabado 
        _cOrdem:=AllTrim(StrZero(10000-Val(ZL6T->ZL6_ORDGRU),4))+_cOrdem
        _nCusto:=0//ZL6T->ZL6_CUSPR = "N"
	    If ZL6T->ZL6_CUSPR = "S"
	       _nCusto:=1
	    ElseIf ZL6T->ZL6_CUSPR = "A"
	       _nCusto:=2
	    ElseIf ZL6T->ZL6_CUSPR = "B"
	       _nCusto:=3
        EndIf
	
		aAdd( _aze1, {	xFilial("ZE0"),;															//01*
					AllTrim(ZL6T->ZL6_TPCUS),;														//02 *
					AllTrim(ZL6T->ZL6_DTPCUS),;														//03
					AllTrim(ZL6T->ZL6_CODEVE),;														//04	
					AllTrim(ZL6T->ZL6_DESEVE),;			 											//05
					AllTrim(ZL6T->ZL6_SUBEVE),;														//06
					AllTrim(ZL6T->ZL6_DSUBEV),;														//07
					AllTrim(ZL6T->ZL6_GRPCUS),;														//08
					AllTrim(ZL6T->ZL6_DGRCUS),;														//09
					_nQtdSin,;																		//10 - QTDE
					_nVlrSin,;																		//11 - VLR
					(SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4)),;					//12
					AllTrim(ZL6T->ZL6_REGRA),;														//13
					_cordem,;																		//14
					AllTrim(ZL6T->ZL6_CODPRO),;														//15
					ZL6T->ZL6_TCUSTO,;																//16		
					ZL6T->ZL6_TUNID,;  																//17
					ZL6T->ZL6_CODPRO,;                                                              //18
					ZL6T->ZL6_CENTRO,; 																//19				
					ZL6T->ZL6_OBSERV,; 																//20  ZL6_OBSERV
					_nCusto,;		                                                                //21  ZL6_CUSPR
					ZL6T->ZL6_FRETPE,;                                                              //22
					ZL6T->ZL6_MIX,;                                                                 //23
					ZL6T->ZL6_QTD,;                                                                 //24
					ZL6T->ZL6_GRPCUF,;                                                              //25
					ZL6T->ZL6_REDIME,;                                                              //26  ZL6_REDIME
					_nQtdemKG})                                                                     //27  _nQtdSin * fATOR
	ElseIf AllTrim(ZL6T->ZL6_TPCUS) $ '000004,000005,000006'  // 02-CUSTO E ESTOQUE MP (000004,000005) e 03-ESTOQUE FINAL (000006).  PLANILHAS 02 E 03
		aAdd(_azeNew,{	xFilial("ZE0"),;															//01*
					AllTrim(ZL6T->ZL6_TPCUS),;														//02 *
					AllTrim(ZL6T->ZL6_DTPCUS),;														//03
					AllTrim(ZL6T->ZL6_CODEVE),;														//04	*
					AllTrim(ZL6T->ZL6_DESEVE),;			 											//05
					AllTrim(ZL6T->ZL6_SUBEVE),;														//06      *
					Upper(AllTrim(ZL6T->ZL6_DSUBEV)),;												//07  DESCRICAO
					AllTrim(ZL6T->ZL6_GRPCUS),;														//08   *
					AllTrim(ZL6T->ZL6_DGRCUS),;														//09
					_nQtdSin,;																		//10 - QTDE INICIAL
					_nVlrSin,;																		//11 - VALOR
					(SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4)),;					//12
					AllTrim(ZL6T->ZL6_REGRA),;														//13
					_cordem,;																		//14  *
					AllTrim(ZL6T->ZL6_CODPRO),;														//15 CODIGO DE PRODUTOS
					ZL6T->ZL6_TCUSTO,;																//16		
					ZL6T->ZL6_TUNID ,; 																//17
					AllTrim(ZL6T->ZL6_GRPPRO),;                                                     //18 GRUPOS
					ZL6T->ZL6_CENTRO,; 																//19				
					ZL6T->ZL6_OBSERV,; 																//20  
					_lTemEstoquenaDT,; 																//21 
					ZL6T->ZL6_FILIS ,; 																//22
					_aProdutos      ,; 																//23
					AllTrim(ZL6T->ZL6_MOBSER),;														//24
					AllTrim(ZL6T->ZL6_CLIENTE)})													//25
	EndIf

	ZL6T->(DBSkip())
EndDo

ZL6T->( DBCloseArea() )
_oself:IncRegua2("OK")
//  1                2           14                       8             4             6
//	xFilial("ZE0") + ZL6_TPCUS + (ZL6_ORDGRU+ZL6_ORDEM) + ZL6_GRPCUS  + ZL6_CODEVE  + ZL6_SUBEVE
_aze0  := aSort(_aze0  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] > y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })
_aze1  := aSort(_aze1  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] > y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })
_azeNew:= aSort(_azeNew,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] > y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })

//Total custo operacional
For _nI := 1 To Len(_aze0)
	_nvalope += _aze0[_nI][11]
Next

_aTotCustoOp:={}
_oself:SetRegua1( Len(_aze1)*2 )
_aCustoMP:={}

If _lTemMateriaPrima .And. Len(_aze1) > 0
   _oself:IncRegua1("2-Calculando Valor Unitario da MP ...")

   _aCustoMP     := MEST9PCustoMP(,_aZeNew,.T.,_oSelf)  //Essa função devolve as primeiras 4 linhas do _aCustoMP
   _nDifLeite    := MEST9PEstoqueMP(,_aZeNew,.T.,_oSelf)// Roda os codigos "000004" para gravar a quinta linha
   _aCustoMP[5,2]:= _nDifLeite
EndIf

//total geral do leite para custo operacional
_aTotais := U_MEST009E(MV_PAR01,MV_PAR02,MV_PAR05,MV_PAR06,3,_oself,@_lEnd)
If _lLoop
   Return .F.
EndIf
_nTotLei := _aTotais[1]
_nTotSoro:= _aTotais[2]

//Total de litragem do leite para produtos acabados
For _nI := 1 To Len(_aze1)
	_oself:IncRegua1("2-Processando Regras...")

	If _lTemMateriaPrima .And. "MATERIA PRIMA" $ _aze1[_nI][5]
	    If "MATERIA GORDA" $ _aze1[_nI][7] .And. _aze1[_nI][20] = "F"
			_aze1[_nI][11]:=(  _aCustoMP[1,7]*_aze1[_nI][11] )
			If _aze1[_nI][24] = "2" .And. _aze1[_nI][11] > 0 //ZL6_QTD
				_aze1[_nI][11]:=(_aze1[_nI][11]*-1)
			EndIf 
																//ZL6_OBSERV             //ZL6_QTD
			_aze1[_nI][07]:= AllTrim(_aze1[_nI][07])+" ("+_aze1[_nI][20]+")"+" ("+_aze1[_nI][24]+")"
							//ZL6_DSUBEV            //ZL6_OBSERV
		ElseIf "DIFERENCA" $ _aze1[_nI][07] .And. _aze1[_nI][20] = "3"
			_nQtPerda:=0                                    //"DIFERENCA ESTOQUE MP"
			For _nAux := 1 To Len(_aze1)             
				If _aze1[_nAux][02]==_aze1[_nI][02] .and.;// ZL6_TPCUS
					_aze1[_nAux][04]==_aze1[_nI][04] .and.;// ZL6_CODEVE
					_aze1[_nAux][08]==_aze1[_nI][08] .and.;// ZL6_GRPCUS
					"PERDA MP" $ _aze1[_nAux][07]      // ZL6_DSUBEV
					_nQtPerda+=_aze1[_nAux][10]//Tem varias linhas de perdas positivas e negativas
				EndIf
			Next 
			
			_nQtdeNew:=((_aze1[_nI][10]+_nQtPerda)/_nTotLei) * _aCustoMP[5,2]
			_aze1[_nI][11]:=(  _nQtdeNew * _aCustoMP[1,2] )//"LEITE IN NATURA" Csuto

			If _aze1[_nI][24] = "2" .And. _aze1[_nI][11] > 0 //ZL6_QTD
				_aze1[_nI][11]:=(_aze1[_nI][11]*-1)
			EndIf 
															//ZL6_OBSERV            //ZL6_QTD              QUANTIDADE PROD                          QUANTIDADE PERDA
			_aze1[_nI][07]:= AllTrim(_aze1[_nI][07])+" ("+_aze1[_nI][20]+")"+" ("+_aze1[_nI][24]+") ("+AllTrim(Str(_aze1[_nI][10],20,2))+") ("+AllTrim(Str(_nQtPerda,20,2))+")"
			_aze1[_nI][10]:=_nQtdeNew
		ElseIf !Empty(_aze1[_nI][22])//ZL6T->ZL6_FRETPE//22
			_nPos:=0
			If _aze1[_nI][22]     = '1'//"LEITE IN NATURA + TERCEIROS"
				_nPos:=1
			ElseIf _aze1[_nI][22] = '2'//"SORO DE LEITE
				_nPos:=2
			ElseIf _aze1[_nI][22] = '3'//"SORO DE LEITE CONCENTRADO
				_nPos:=3
			ElseIf _aze1[_nI][22] = '4'//"CREME DE LEITE
				_nPos:=4
			ElseIf _aze1[_nI][22] = '5'//"SORO DE LEITE PRE-CONCENTRADO
				_nPos:=6
			EndIf

			If _nPos <> 0
				If "FRETE" $ _aze1[_nI][7] 
					_aze1[_nI][11]:=(  _aCustoMP[_nPos,3]*_aze1[_nI][10] )
				Else
					If _aze1[_nI][23] = 'L'//ZL6T->ZL6_MIX//23
					_aze1[_nI][11]:=( (_aCustoMP[_nPos,2]-_aCustoMP[_nPos,3])*_aze1[_nI][10] )
					Else//'P'
						_aze1[_nI][11]:=(  _aCustoMP[_nPos,2]*_aze1[_nI][10] )
					EndIf
				EndIf
			
				If _aze1[_nI][24] = "2" .And. _aze1[_nI][11] > 0 //ZL6_QTD
					_aze1[_nI][11]:=(_aze1[_nI][11]*-1)
				EndIf 
				_aze1[_nI][07]:= AllTrim(_aze1[_nI][07])+" ("+_aze1[_nI][23]+") ("+_aze1[_nI][24]+") ("+_aze1[_nI][22]+")"
			EndIf   
		EndIf
	EndIf	

	If AllTrim(_aze1[_nI][16]) == "6"                    
		_cUN  :=""
		_cProd:=AllTrim(_aze1[_nI][15])
		_nPos :=AT(";",_cProd)
		If _nPos > 1
			_cProd:=SubStr(_cProd,1,_nPos-1)
		EndIf
		If _aze1[_nI][17] == "S"  //Se usa segunda unidade puxa unidade, senão é litro
			_cUN:=Posicione("SB1",1,xFilial("SB1")+_cProd,"B1_SEGUM")
		Else
			_cUN:=Posicione("SB1",1,xFilial("SB1")+_cProd,"B1_UM")
		EndIf
		
		If Len(_atotlei) == 0
			aAdd(_atotlei,{_aze1[_nI][08],_aze1[_nI][10],_aze1[_nI][11],_cUN})
		Else
			_np := aScan(_atotlei,{|_vAux|_vAux[1]==_aze1[_nI][08]})
			If _np > 0
				_atotlei[_np][02] +=  _aze1[_nI][10]
				_atotlei[_np][03] +=  _aze1[_nI][11]
			Else
				aAdd(_atotlei,{_aze1[_nI][08],_aze1[_nI][10],_aze1[_nI][11],_cUN})//"LT"
			EndIf
		EndIf
	EndIf

	If AllTrim(_aze1[_nI][05]) == "CUSTO OPERACIONAL" 
       _np := aScan(_aTotCustoOp,{|_vAux|_vAux[1]==_aze1[_nI][08]})
       If _np > 0
		  _aTotCustoOp[_np][02] +=  _aze1[_nI][10]
       Else
		  aAdd(_aTotCustoOp,{_aze1[_nI][08],_aze1[_nI][10]})//"LT"
       EndIf
	EndIf
Next

_oself:IncRegua1("3-Processando Regras...")

//Atualiza custo operacional se existir
For _nI := 1 To Len(_aze1)
    _oself:IncRegua1("4-Processando Regras...")
    
	If AllTrim(_aze1[_nI][05]) == "CUSTO OPERACIONAL" .OR.;
		AllTrim(_aze1[_nI][05]) == "CUSTO OPERACIONAL UNIFICADO" .Or. ;
		(!'ESTOQUE INICIAL' $ Upper(AllTrim(_aze1[_nI][05])) .And. _aze1[_nI][20] = "D")
		If _aze1[_nI][20] = "D"
			_np := aScan(_aTotCustoOp,{|_vAux|_vAux[1]==_aze1[_nI][08]})
			If _np > 0
				nTots:=_aTotCustoOp[_np,2]
				nTots:=(( nTots /_ntotlei) * _aze1[_nI][11])
				_aze1[_nI][11] := nTots
			EndIf
		Else
			_np := aScan(_atotlei,{|_vAux|_vAux[1]==_aze1[_nI][08]})
			If _np > 0
				If  AllTrim(_aze1[_nI][05]) == "CUSTO OPERACIONAL" .And. xFilial("ZL6") = "10"
					If !_lMostraSoro  
						_aze1[_nI][10] := _nTotLei+_nTotSoro
						_aze1[_nI][11] := ((_nvalope/(_ntotlei+_nTotSoro) ) * _aze1[_nI][10])
					ElseIf "SORO" $ AllTrim(_aze1[_nI][9])//Soros: "00090010501;00090020501"
						_aze1[_nI][10] := _nTotSoro
						_aze1[_nI][11] := (((_nvalope/4)/_nTotSoro) * _aze1[_nI][10])
					Else
						_aze1[_nI][11] := (( (_nvalope-(_nvalope/4)) /_ntotlei) * _aze1[_nI][10])
					EndIf
				Else
					_aze1[_nI][11] := ((_nvalope/_ntotlei) * _aze1[_nI][10])
				EndIf
			EndIf
		EndIf
	EndIf
Next

_oself:SetRegua1( Len(_aze1) )
_cTotReg:=AllTrim(Str(Len(_aze1)))
_nConta :=0
		
//Atualiza quantidade e valor do creme (M.G.) usada nas manteigas por rateio
For _nI := 1 To Len(_aze1)
	_nConta++
	_oself:IncRegua1("5-Processando Regras "+Str(_nConta,4)+" de "+_cTotReg )

	If Substring(AllTrim(_aze1[_nI][09]),1,8) == "MANTEIGA" .And. AllTrim(_aze1[_nI][05]) == "MATERIA PRIMA" .And. AllTrim(_aze1[_nI][20]) <> "B"
		_ccLeite 	:= "'24511001','24511002','24001006','24003006','24002006','24001001','24001004','24002001','24002004','24003004','24004001','24004003'"
		_ccMg500 	:= '24401001'
		_ccMg200 	:= '24401002'
		_aQtde	 	:= {}
		_dinicial	:= MV_PAR05
		_dfinal		:= MV_PAR06
		_nVlrMix 	:= 0
		_nVMixSF	:= 0
		_cEmpresa	:= SubStr(FWFilialName( cEmpAnt , xFilial("ZL6") , 2 ),8,35)
		
		DBSelectArea("ZL2")
		Zl2->( DBSetOrder(2) )

		If Empty(MV_PAR10)
			If ZL2->( DBSeek( xFilial("ZL2") + AllTrim(_cempresa)) )
				If ZL2->ZL2_DTUMIX >= _dinicial .And. ZL2->ZL2_DTUMIX <= ( _dfinal + 15 )
					_nVlrMix := ZL2->ZL2_ULTMIX
					_nVMixSF := ZL2->ZL2_ULMISF
				Else
					_nVlrMix := MV_PAR10
				EndIf
			Else
				_nVlrMix := MV_PAR10
			EndIf
		Else
			_nVlrMix := MV_PAR10
		EndIf					
			
		DBCloseArea()	
		
		_cQuery:= " Select Round((tmp.muq/(tmp.qm2+tmp.qm5)*tmp.qm5),2) q5, Round((tmp.muq/(tmp.qm2+tmp.qm5)*tmp.qm2),2) q2 from ( "
		_cQuery+= " Select m2.qtde QM2, m5.qtde QM5, (select sum(d3_quant) from "+ RetSqlName("SD3") + " SD3 " 
		_cQuery+= " where sd3.d3_FILIAL = '" + xFilial("SD3") + "'"
		_cQuery+= " and sd3.d_e_l_e_t_ = ' ' and d3_cf = 'DE1' 
		_cQuery+= " and d3_cod = '"+AllTrim(_aze1[_nI][15])+"'
		_cQuery+= " and d3_cc in ("+_ccLeite+")
		_cQuery+= " and d3_estorno <> 'S'
		_cQuery+= " and d3_emissao between '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "' ) muq from "
		_cQuery+= " (select sum(d3_quant) qtde, d3_cod from "+ RetSqlName("SD3") + " SD3 "
		_cQuery+= " where sd3.d3_FILIAL = '" + xFilial("SD3") + "'"
		_cQuery+= " and sd3.d_e_l_e_t_ = ' ' and d3_cf = 'RE1' "
		_cQuery+= " and d3_cc in ('"+_ccMg200+"')
		_cQuery+= " and d3_estorno <> 'S' and d3_cod = '"+AllTrim(_aze1[_nI][15])+"' "
		_cQuery+= " and d3_emissao between '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
		_cQuery+= " group by d3_cod ) m2
		_cQuery+= " join (
		_cQuery+= " select sum(d3_quant) qtde, d3_cod from "+ RetSqlName("SD3") + " SD3 "
		_cQuery+= " where sd3.d3_FILIAL = '" + xFilial("SD3") + "'"
		_cQuery+= " and sd3.d_e_l_e_t_ = ' ' and d3_cf = 'RE1' "
		_cQuery+= " and d3_cc in ('"+_ccMg500+"')
		_cQuery+= " and d3_estorno <> 'S' and d3_cod = '"+AllTrim(_aze1[_nI][15])+"' "
		_cQuery+= " and d3_emissao between '" + DToS(_dinicial)+ "' AND '" + DToS(_dfinal) + "'"
		_cQuery+= " group by d3_cod ) m5
		_cQuery+= " on m2.d3_cod = m5.d3_cod ) tmp
			
        MPSysOpenQuery( _cQuery ,"SD3TT" ) 
		DBSelectArea("SD3TT")

		If .not. SD3TT->( Eof() )
			aAdd(_aQtde,{SD3TT->Q5,SD3TT->Q2})
		Else
			aAdd(_aQtde,{0,0})
		EndIf

		SD3TT->( DBCloseArea() )

		If SubStr(AllTrim(_aze1[_nI][09]),1,12) == "MANTEIGA 200"
			_aze1[_nI][10] := _aQtde[1][2]
			If _nVlrMix > 0
				_aze1[_nI][11] := _aQtde[1][2] * _nVlrMix
			Else	
				_aze1[_nI][11] := _aQtde[1][2] * _nVMixSF
			EndIf	
		ElseIf SubStr(AllTrim(_aze1[_nI][09]),1,12) == "MANTEIGA 500"
			_aze1[_nI][10] := _aQtde[1][1]
			If _nVlrMix > 0
				_aze1[_nI][11] := _aQtde[1][1] * _nVlrMix
			Else	
				_aze1[_nI][11] := _aQtde[1][1] * _nVMixSF
			EndIf	
		EndIf	
	EndIf
Next		

//Algutina itens regra 2
_nI := 1

_aze0b := _aze0
_aze0 := {}

_oself:IncRegua1("6-Processando Regras...")

//  1                2           14                       8             4             6
//	xFilial("ZE0") + ZL6_TPCUS + (ZL6_ORDGRU+ZL6_ORDEM) + ZL6_GRPCUS  + ZL6_CODEVE  + ZL6_SUBEVE
_aze0b:= aSort(_aze0b  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] < y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })//INVERTE A ORDEM

While _nI <= Len(_aze0b)
	_np := aScan(_aze0,{|_vAux|_vAux[01]==_aze0b[_nI][01] .and.;
							   _vAux[02]==_aze0b[_nI][02] .and.;
							   _vAux[04]==_aze0b[_nI][04] .and.;
							   _vAux[08]==_aze0b[_nI][08] .and.;
							   _vAux[14]==_aze0b[_nI][14] }) //ZL6_ORDEM

	If _aze0b[_nI][13] == "2" .And. _np > 0//ZL6_REGRA
		_aze0[_np][10]  +=  _aze0b[_nI][10]
		_aze0[_np][11]  +=  _aze0b[_nI][11]	
	Else	
		aAdd(_aze0,_aze0b[_nI])
	EndIf
	_nI++
EndDo
//  1                2           14                       8             4             6
//	xFilial("ZE0") + ZL6_TPCUS + (ZL6_ORDGRU+ZL6_ORDEM) + ZL6_GRPCUS  + ZL6_CODEVE  + ZL6_SUBEVE
_aze0:= aSort(_aze0  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] > y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })//DESINVERTE A ORDEM

_nI := 1
_aze1b := _aze1
_aze1 := {}

_oself:IncRegua1("7-Processando Regras...")

//  1                2           14                       8             4             6
//	xFilial("ZE0") + ZL6_TPCUS + (ZL6_ORDGRU+ZL6_ORDEM) + ZL6_GRPCUS  + ZL6_CODEVE  + ZL6_SUBEVE
_aze1b:= aSort(_aze1b  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] < y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })//INVERTE A ORDEM
While _nI <= Len(_aze1b) 
	_np := aScan(_aze1,{|_vAux|_vAux[01]==_aze1b[_nI][01] .and.;
							   _vAux[02]==_aze1b[_nI][02] .and.;
							   _vAux[04]==_aze1b[_nI][04] .and.;
							   _vAux[08]==_aze1b[_nI][08] .and.;
							   _vAux[14]==_aze1b[_nI][14] }) //ZL6_ORDEM
	If _aze1b[_nI][13] == "2" .And. _np > 0//ZL6_REGRA
			_aze1[_np][10]  +=  _aze1b[_nI][10]
			_aze1[_np][11]  +=  _aze1b[_nI][11]	
	Else
		aAdd(_aze1,_aze1b[_nI])
	EndIf
	_nI++
EndDo

//  1                2           14                       8             4             6
//	xFilial("ZE0") + ZL6_TPCUS + (ZL6_ORDGRU+ZL6_ORDEM) + ZL6_GRPCUS  + ZL6_CODEVE  + ZL6_SUBEVE
_aze1:= aSort(_aze1  ,,,{|x,y| x[1]+x[2]+x[14]+x[8]+x[4]+x[6] > y[1]+y[2]+y[14]+y[8]+y[4]+y[6] })//DESINVERTE A ORDEM

_oself:IncRegua1("9-Processando Regras...")

_aGrupos:={}
For _nI := 1 To Len(_aze1)
   If !Empty(_aze1[_nI][25])//ZL6_GRPCUF
	  If aScan(_aGrupos,{|G| G[1]==_aze1[_nI][25] })  = 0//ZL6_GRPCUF 
         aAdd(_aGrupos,{_aze1[_nI][25],0})//ZL6_GRPCUF
      EndIf   
   EndIf   
Next

For _nI := 1 To Len(_aze1)
	If (nPos:=aScan(_aGrupos,{|G| G[1] ==_aze1[_nI][8] }) ) <> 0  .And._aze1[_nI][2] == "000002" .AND.;
	   ("MATERIA PRIMA" $ _aze1[_nI][5] .Or. "FRETE" $ _aze1[_nI][5] .Or. "INSUMOS" $ _aze1[_nI][5])
       _aGrupos[nPos,2]+=_aze1[_nI][11]
	EndIf
Next

_oself:IncRegua1("10-Processando Regras...")

For _nI := 1 To Len(_aze1)
	If !Empty(_aze1[_nI][25])           //ZL6_GRPCUF                    //ZL6_DESEVE
		If (nPos:=aScan(_aGrupos,{|G| G[1]==_aze1[_nI][25]  }) ) <> 0 //ZL6_GRPCUF 
			_cQuery:=""
			nQtde:=U_MEST009A(MV_PAR05,MV_PAR06,"PR0",_aze1[_nI][15],"")[2]
			_aze1[_nI][11]:=(_aGrupos[nPos,2]/nQtde)*_aze1[_nI][10]
		EndIf
	EndIf
Next

Return

/*
===============================================================================================================================
Programa----------: MEST009E2
Autor-------------: Josue Danich Prestes
Data da Criacao---: 23/11/2015
Descricao---------: Gera corpo de custos do Excel
Parametros--------: _AZE0 - array com dados de custo do grupo
						_ctitulo - Titulo do grupo
						_ntoteli2 - total de litragem ou unidades
						_cproduto - produto do grupo
						_cun - unidade do produto
Retorno-----------: _axml
===============================================================================================================================
*/

Static Function MEST009E2(_aze0,_ctitulo,_ntotlei2,_cproduto,_cun)

Local _axml 		:= {}
Local _cult 		:= AllTrim(_aze0[01][08])+AllTrim(_aze0[01][04])
Local _nqtot 		:= 0
Local _nvtot		:= 0 
Local _nI 			:= 1 
Local _cult2 		:= AllTrim(_aze0[01][09])
Local _cult3		:= AllTrim(_aze0[01][08])+AllTrim(_aze0[01][04])+AllTrim(_aze0[01][06])
Local _nsubtot		:= 0 
Local _ntotger		:= 0
Local _nporce		:= 0
Local _asubs		:= {}
Local _ni2			:= 1
Local _nsubtot2		:= 0
Local _lsub			:= .F.
Local _ctitulo2		:= _ctitulo
Local _aicst		:= {}
Local _aExp 		:= {}  //Quantidade expedida
Local _aFret		:= {}  //Valor Frete
Local _nExp 		:= 0
Local _nExpD 		:= 0
Local _nExpF 		:= 0
Local _nExpT 		:= 0 ,  nX   , nPos

Default _cun := SuperGetMV("IT_UMVOLLE",.F.,"LT")
Default _ntotlei2 := 0
_ntotlei := _ntotlei2

//Monta cabeçalho da seção
If _nPag > 1
	aAdd( _axml, '   <Row ss:AutoFitHeight="0" ss:Height="18">')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0" ss:Height="18">')
	aAdd( _axml, '   </Row>')
EndIf

aAdd( _axml, '   <Row ss:AutoFitHeight="0" ss:Height="18">')
aAdd( _axml, '    <Cell ss:MergeDown="1" ss:StyleID="s69"/>')
aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
aAdd( _axml, '    <Cell ss:MergeAcross="4" ss:StyleID="s73"><Data ss:Type="String">' + _ctitulo2 + '</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s74"><Data ss:Type="Number">' + StrZero(_nPag,3) + '</Data></Cell>')
aAdd( _axml, '   </Row>')
aAdd( _axml, '   <Row ss:AutoFitHeight="0" ss:Height="18">')
aAdd( _axml, '    <Cell ss:Index="2" ss:StyleID="s71"/>')
If "UNIFICADO" $ _aze0[1][3]
	If xFilial("ZL6") == "23"
		aAdd( _axml, '    <Cell ss:MergeAcross="4" ss:StyleID="s73"><Data ss:Type="String">POR LITROS PRODUZIDOS  -  ITALAC/SUL UNIFICADO </Data></Cell>')
	ElseIf xFilial("ZL6") == "10"
		aAdd( _axml, '    <Cell ss:MergeAcross="4" ss:StyleID="s73"><Data ss:Type="String">POR LITROS PRODUZIDOS  -  ITALAC/RONDONIA UNIFICADO </Data></Cell>')
	EndIf		
Else	
	aAdd( _axml, '    <Cell ss:MergeAcross="4" ss:StyleID="s73"><Data ss:Type="String">POR LITROS PRODUZIDOS  - ' + FWFilialName( cEmpAnt , xFilial("ZL6") , 2 )  + '</Data></Cell>')
EndIf	
aAdd( _axml, '    <Cell ss:StyleID="s75"><Data ss:Type="String">' + mesextenso(month(MV_PAR05)) + '/' + AllTrim(Str(year(MV_PAR05))) + '</Data></Cell>')
aAdd( _axml, '   </Row>')
aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:StyleID="s76"/>')
aAdd( _axml, '    <Cell ss:StyleID="s77"/>')
aAdd( _axml, '    <Cell ss:StyleID="s78"/>')
aAdd( _axml, '    <Cell ss:StyleID="s79"/>')
aAdd( _axml, '    <Cell ss:StyleID="s80"/>')
aAdd( _axml, '    <Cell ss:StyleID="s81"/>')
aAdd( _axml, '    <Cell ss:StyleID="s82"/>')
aAdd( _axml, '    <Cell ss:StyleID="s83"/>')
aAdd( _axml, '   </Row>')
aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
aAdd( _axml, '    <Cell ss:StyleID="s85"/>')
aAdd( _axml, '    <Cell ss:StyleID="s86"/>')
aAdd( _axml, '    <Cell ss:StyleID="s87"/>')
aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
aAdd( _axml, '   </Row>')

//Só trás dolar e litragem para filiais menores que 90 (não CD)

aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:MergeAcross="1" ss:StyleID="s89"><Data ss:Type="String">DOLAR COML</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s94"><Data ss:Type="Number">'+AllTrim(Str(_nTotdol))+'</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s95"/>')
aAdd( _axml, '    <Cell ss:StyleID="s86"/>')
aAdd( _axml, '    <Cell ss:StyleID="s96"/>')
aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
aAdd( _axml, '   </Row>')

_cTesteA:=_ctitulo+CRLF
_cTesteA:=_ctitulo2+CRLF
_cTesteA+="ZL6_TPCUS;ZL6_DTPCUS;ZL6_DESEVE;ZL6_DSUBEV;PROD;ZL6_REDIME;_nQtdSin;_nQtdemKG;_nQtdeProd;_aze0[nX][21] * _aFactoMike[nPos,3];ZL6_OBSERV"+CRLF
_nRendim:=0
_nQtdeProd:=0
_cImpProdKG:=""
_lImpProdKG:=.F.
For nX := 1 To Len(_aze0)
	_nQtdemKG:=0
	If AllTrim(_aze0[nX][19]) $ "S,A"//ZL6_REDIME
		If AllTrim(_aze0[nX][19]) = "S"//ZL6_REDIME
			_nQtdeProd+=_aze0[nX][10]//_nQtdSin
			For nPos := 1 To Len(_aFactoMike)
				If _aFactoMike[nPos,4] $ AllTrim(_aze0[nX][15])//posicao 4 codigos 
					_aFactoMike[nPos,3] := (_nQtdeProd/_nTotLei)//Rendimento  do leite em PÓ
				EndIf
			Next
		ElseIf AllTrim(_aze0[nX][19]) = "A"//ZL6_REDIME
			_nQtdemKG:=_aze0[nX][21]
			If (nPos:=aScan(_aFactoMike, {|P| P[1] $ AllTrim(_aze0[nX][15]) })) <>  0 .And. _aFactoMike[nPos,3] <> 0 
				_nQtdemKG := ( _aze0[nX][21] * _aFactoMike[nPos,3] )
			EndIf
			_nQtdeProd+=_nQtdemKG//_nQtdemKG
		EndIf  
	EndIf
	If AllTrim(_aze0[nX][19]) = "A"//ZL6_REDIME
		_lImpProdKG:=.T.
	EndIf
	If "PERDAS P.A." $ _aze0[nX][7]
		_cImpProdKG:=AllTrim(_aze0[nX][15])
	EndIf
	_cTesteA+="'"+_aze0[nX][2]+";"+_aze0[nX][3]+";"+_aze0[nX][9]+";'"+_aze0[nX][7]+";'"+StrTran(_aze0[nX][15],";",",")+";"+_aze0[nX][19]+";"+;
	Str(_aze0[nX][10])+";"+Str(_aze0[nX][21])+";"+Str(_nQtdeProd)+";"+Str(_nQtdemKG)+";"+_aze0[nX][20]+CRLF
Next

If _lImpProdKG
	_nPos:=AT(";",_cImpProdKG)
	If _nPos > 1
		_cImpProdKG:=SubStr(_cImpProdKG,1,_nPos-1)
	EndIf
	SB1->(DBSetOrder(1))
	SB1->(DBSeek(xFilial("SB1")+_cImpProdKG)) 
	cRet:=AllTrim(Posicione("ZA2",1,xFilial("ZA2")+SB1->B1_I_NIV3,"ZA2_DESCRI"))
	_cTesteA+=CRLF
	_cTesteA+="ZA2_DESCRI = "+cRet+CRLF
	If "KG" $ Upper(cRet)
		nFator:=Val(StrTran(cRet,",","."))
	Else
		nFator:=Val(cRet)/1000
	EndIf   
	_cTesteA+="nFator = "+Str(nFator)+CRLF
	_cTesteA+="_nTotLei = "+Str(_nTotLei)+CRLF
	_nProdKG := nFator * _nTotLei
	_cTesteA+="_nProdKG = "+Str(_nProdKG)+CRLF
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:MergeAcross="1" ss:StyleID="s89"><Data ss:Type="String">PRODUCAO KG</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_nProdKG)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s95"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s86"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s96"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
	aAdd( _axml, '   </Row>')

	_nRendim:=(_nQtdeProd/_nProdKG)
	_cTesteA+=" _nQtdeProd/_nProdKG : "+Str(_nQtdeProd)+ " / "+ Str(_nProdKG)+CRLF
Else
   _nRendim:=(_nQtdeProd/_nTotLei)
    _cTesteA+=" _nQtdeProd/_nTotLei : "+Str(_nQtdeProd)+ " / "+ Str(_nTotLei)+CRLF
EndIf

If _nQtdeProd <> 0
   aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
   aAdd( _axml, '    <Cell ss:MergeAcross="1" ss:StyleID="s89"><Data ss:Type="String">RENDIMENTO</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_nRendim)) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s95"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s86"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s96"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s97"/>')
   aAdd( _axml, '   </Row>')
EndIf

aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:MergeAcross="1" ss:StyleID="s99"><Data ss:Type="String">' + If(xFilial("ZL6") = "10",'LEITE/QUEIJO/LEITE EM PO/MANTEIGA','') + '</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s103"><Data ss:Type="String">' + TRANSFORM(_nTotLei, "@E 999,999,999.99" ) + ' ' + AllTrim(_cun) + '</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s104"><Data ss:Type="String">QUANTIDADE</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s105"><Data ss:Type="String">UNIT.</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s106"><Data ss:Type="String">VALORES ( R$ )</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s107"><Data ss:Type="String">P. R$(P/LT )</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s108"><Data ss:Type="String">P. US$(P/LT )</Data></Cell>')
aAdd( _axml, '   </Row>')

If _cTitulo = "CUSTO OPERACIONAL" .And. xFilial("ZL6") = "10"//LEITE/QUEIJO/LEITE EM PO/MANTEIGA
   aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
   aAdd( _axml, '    <Cell ss:MergeAcross="1" ss:StyleID="s99"><Data ss:Type="String">SORO</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s103"><Data ss:Type="String">'+TRANSFORM(_nTotSoro, "@E 999,999,999.99" ) + ' ' + AllTrim(_cun) + '</Data></Cell>')
   aAdd( _axml, '   </Row>')
EndIf

aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:StyleID="s109"/>')
aAdd( _axml, '    <Cell ss:StyleID="s110"/>')
aAdd( _axml, '    <Cell ss:StyleID="s111"/>')
aAdd( _axml, '    <Cell ss:StyleID="s112"/>')
aAdd( _axml, '    <Cell ss:StyleID="s86"/>')
aAdd( _axml, '    <Cell ss:StyleID="s113"/>')
aAdd( _axml, '    <Cell ss:StyleID="s114"/>')
aAdd( _axml, '    <Cell ss:StyleID="s114"/>')
aAdd( _axml, '   </Row>')

//Monta total geral e subtotais para usar na montagem do corpo do excel
_cult2 := AllTrim(_aze0[_nI][08]) 
_nTotCusP := 0//CUSTO PRODUCAO
_nTotCusA := 0//CUSTO PRODUTO ABERTO

For _nI := 1 To Len(_aze0)
	If AllTrim(_aze0[_nI][13]) <> "4"//ZL6_REGRA
		If _cult2 != AllTrim(_aze0[_nI][08]) //ZL6_CODEVE
			aAdd(_asubs, _nsubtot)
			_nTotCusP += _nsubtot//CUSTO PRODUCAO
			_nsubtot := 0
			_cult2 := AllTrim(_aze0[_nI][08])//ZL6_CODEVE 
		EndIf  

		If AllTrim(_aze0[_nI][13]) <> "5" //ZL6_REGRA
			If !(Len(_aze0[_nI]) >= 18 .And. ValType(_aze0[_nI][18]) = "N" .And. _aze0[_nI][18] <> 0)//--> <> N //soma tudo que não tiver a regra do ZL6T->ZL6_CUSPR = "S" e "A"
				_nsubtot += _aze0[_nI][11]
			EndIf
			_ntotger += _aze0[_nI][11]
		EndIf

		If "EMBALAGENS" $ _aze0[_nI][09]//ZL6_DESEVE
			_nTotCusA += _aze0[_nI][11]//CUSTO PRODUTO ABERTO
		EndIf   
	EndIf
Next

aAdd(_asubs, _nsubtot)
_nTotCusP += _nsubtot//CUSTO PRODUCAO

//Para registros marcados como custo médio de produção atualiza custo pelo subtotal de produção
_ncusmed := _nTotCusP / _ntotlei//CUSTO PRODUCAO
_nCusAbe := _nTotCusA / _ntotlei//CUSTO PRODUTO ABERTO
_lrecalc := .F.

For _nI := 1 To Len(_aze0)
	If _aze0[_nI][3] == "PRODUTOS ACABADOS"                                           //                             _aze0[_nI][18] == 0 = "N" = ZL6T->ZL6_CUSPR 
		If  Len(_aze0[_nI]) >= 18 .And. ValType(_aze0[_nI][18]) = "N" .And. _aze0[_nI][18] <> 0//--> <> N
			If _aze0[_nI][18] = 1            // ZL6T->ZL6_CUSPR = "S" = 1 = _aze0[_nI][18]
				_aze0[_nI][11] := _ncusmed * _aze0[_nI][10]//CUSTO PRODUCAO
				_lrecalc := .T.
			ElseIf _aze0[_nI][18] = 2        // ZL6T->ZL6_CUSPR = "A" = 2 = _aze0[_nI][18]
				If _nCusAbe = 0//ZE0_TPCUS+ZE0_GRPCT+ZE0_DSECT
					_nCusAbe:=MEST2BuscaZE0(_aze0[_nI][2],_aze0[_nI][16],_aze0[_nI][7],_aze0[_nI])
				EndIf
				_aze0[_nI][11] := _nCusAbe * _aze0[_nI][10]//CUSTO PRODUTO ABERTO
				_lrecalc := .T.
			EndIf
		EndIf
	EndIf
Next

//ReMonta total geral e subtotais para usar na montagem do corpo do excel
If _lrecalc
	_cult2 := AllTrim(_aze0[1][08])//ZL6_CODEVE
	_asubs := {}
	_nsubtot := 0
	_ntotger := 0 

	For _nI := 1 To Len(_aze0)
		If AllTrim(_aze0[_nI][13]) <> "4"
			If _cult2 != AllTrim(_aze0[_nI][08]) //ZL6_CODEVE
				aAdd(_asubs, _nsubtot)
				_nsubtot := 0
				_cult2 := AllTrim(_aze0[_nI][08]) //ZL6_CODEVE
			EndIf  
	
			If AllTrim(_aze0[_nI][13]) <> "5"
				_ntotger += _aze0[_nI][11]
				_nsubtot += _aze0[_nI][11]
			EndIf
		EndIf
	Next
	aAdd(_asubs, _nsubtot)
EndIf

//Reinicializa contadores e monta corpo do excel
_cult2 	:= AllTrim(_aze0[01][09])
_nsubtot:= 0
_np2v 	:= 0
aAdd(_aze0,{"","XXXXXX","3","XXXXX","5","6","7","XXXXX","9",0,0,"12","","14","15","16","17","18","19","20",0})
aAdd(_aze0,{"","XXXXXX","3","XXXXX","5","6","7","XXXXX","9",0,0,"12","","14","15","16","17","18","19","20",0})
_aSomaEntTrans:={0,0}
For _nI := 1 To Len(_aze0) 
	If _aze0[_nI][20] = "1" .And. "ENTRADAS TRANSFERENCIA" $ AllTrim(_aze0[_nI][7])
       _aSomaEntTrans[1]+=_aze0[_nI][10]
       _aSomaEntTrans[2]+=_aze0[_nI][11]
	EndIf
		
	If AllTrim(_aze0[_nI][13]) <> "4"
		If (AllTrim(_aze0[_nI][08])+AllTrim(_aze0[_nI][04]) == _cult .And. AllTrim(_aze0[_nI][13]) != "3" .And. AllTrim(_aze0[_nI][13]) != "2") .or.;
			(AllTrim(_aze0[_nI][08])+AllTrim(_aze0[_nI][04])+AllTrim(_aze0[_nI][06])  == _cult3 .And. AllTrim(_aze0[_nI][13]) != "3" .And. AllTrim(_aze0[_nI][13]) == "2")
			If AllTrim(_aze0[_nI][13]) <> "5"
				_nqtot 	 +=	_aze0[_nI][10]
				_nvtot	 +=	_aze0[_nI][11]
				_nsubtot +=	_aze0[_nI][11]
				_nsubtot2+=	_aze0[_nI][11]
			Else
				_nqtot 	+= 	_aze0[_nI][10]
				_nvtot	+= 	_aze0[_nI][11]
			EndIf
			_np2v++
		ElseIf AllTrim(_aze0[_nI][13]) != "3"
			_cult := AllTrim(_aze0[_nI][08])+AllTrim(_aze0[_nI][04])//ZL6_CODEVE
			_cult3:= AllTrim(_aze0[01][08])+AllTrim(_aze0[01][04])+AllTrim(_aze0[01][06])
			_nI--
			
			aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
			If _cult2 != AllTrim(_aze0[_nI][08]) .Or. _ni2 == 1//ZL6_CODEVE
				If _ni2 <= Len(_asubs)
					_nporce := (_asubs[_ni2] /_ntotger) * 100
				Else
					_nporce := 0
				EndIf
				
				_ni2++

	            If AllTrim(_aze0[_nI][09]) == "CUSTO FILIAIS" .And. (_lGera4Pla .Or. _lGera2Pla)// .Or. _lGera1Pla)
	            	_aCusto04[2,2]:=_ntotlei
            		_aCusto04[2,3]:=_nvtot
            		_aCusto04[2,4]:=_nvtot / _ntotlei
            	EndIf
				
				aAdd( _axml, '    <Cell ss:StyleID="s153"><Data ss:Type="String">' + _aze0[_nI][09] + ' - ' + transform( _nporce, "@E 999.99%")   +  '</Data></Cell>')
				_cult2 := AllTrim(_aze0[_nI][08])//ZL6_CODEVE
			ElseIf AllTrim(_aze0[_nI][08]) == AllTrim(_aze0[_nI][08])//ZL6_CODEVE
				aAdd( _axml, '    <Cell ss:StyleID="s126"><Data ss:Type="String">  </Data></Cell>')
			Else
				aAdd( _axml, '    <Cell ss:StyleID="s134"><Data ss:Type="String">  </Data></Cell>')
			EndIf
			
			_lsub := .F.
			
			If _nI == Len(_aze0) .Or. AllTrim(_aze0[_nI][08]) != AllTrim(_aze0[_nI+1][08])//ZL6_CODEVE
				_ccod := _aze0[_nI][04]
				_cdesc := _aze0[_nI][05]
				_lsub := .T.
				_nVlr_Unitario:=_nvtot / _nqtot
				_nReal_Litro  :=_nvtot / _ntotlei 
				_nUSS_Litro   :=_nvtot / ( _ntotlei * _nTotdol )
				If _nVlr_Unitario < 0
				   _nVlr_Unitario:=(_nVlr_Unitario*-1)
				EndIf  
				If _nReal_Litro < 0
				   _nReal_Litro:=(_nReal_Litro*-1)
				EndIf  
				If _nUSS_Litro < 0
				   _nUSS_Litro:=(_nUSS_Litro*-1)
				EndIf  

                For nPos := 1 To Len(_aRecalVlrs)
              	   If _aRecalVlrs[nPos,2] $ Upper(LEFT(AllTrim(_cdesc),21))
                       _nVlr_Unitario:=_aRecalVlrs[nPos,3]//(_ntotger / _ntotlei)//P. R$(P/LT )
              	   EndIf
                Next			
				
				aAdd( _axml, '    <Cell ss:StyleID="s156"><Data ss:Type="String">' + _ccod   + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s157"><Data ss:Type="String">' + _cdesc + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_nqtot)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s159"><Data ss:Type="Number">' + AllTrim(Str((_nVlr_Unitario))) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s160"><Data ss:Type="Number">' + AllTrim(Str(_nvtot)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s161"><Data ss:Type="Number">' + AllTrim(Str(_nReal_Litro )) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s162"><Data ss:Type="Number">' + AllTrim(Str(_nUSS_Litro  )) + '</Data></Cell>')
				aAdd( _axml, '   </Row>')
				aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
				aAdd( _axml, '    <Cell ss:StyleID="s116"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s64"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s140"><Data ss:Type="String">Sub-Total.:</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s141"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s142"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s143"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / _ntotlei)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s144"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / ( _ntotlei * _nTotdol ))) + '</Data></Cell>')
				aAdd( _axml, '   </Row>')
				aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
				aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s146"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s147"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
				aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
				aAdd( _axml, '   </Row>')
				
				_nsubtot := 0
			Else
				_ccod := _aze0[_nI][04]
				_cdesc := _aze0[_nI][05]
				_nVlr_Unitario:=_nvtot / _nqtot
				_nReal_Litro  :=_nvtot / _ntotlei 
				_nUSS_Litro   :=_nvtot / ( _ntotlei * _nTotdol )
				If _nVlr_Unitario < 0
				   _nVlr_Unitario:=(_nVlr_Unitario*-1)
				EndIf  
				If _nReal_Litro < 0
				   _nReal_Litro:=(_nReal_Litro*-1)
				EndIf  
				If _nUSS_Litro < 0
				   _nUSS_Litro:=(_nUSS_Litro*-1)
				EndIf  

                For nPos := 1 To Len(_aRecalVlrs)
              	   If _aRecalVlrs[nPos,2] $ Upper(LEFT(AllTrim(_cdesc),21))  .And. _aRecalVlrs[nPos,3] <> 0
                       _nVlr_Unitario:=_aRecalVlrs[nPos,3] //:= (_ntotger / _ntotlei)//P. R$(P/LT )
              	   EndIf
                Next
				
				aAdd( _axml, '    <Cell ss:StyleID="s116"><Data ss:Type="String">' + _ccod   + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s117"><Data ss:Type="String">' + _cdesc + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s119"><Data ss:Type="Number">' + AllTrim(Str(_nqtot)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s120"><Data ss:Type="Number">' + AllTrim(Str(_nVlr_Unitario)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s122"><Data ss:Type="Number">' + AllTrim(Str(_nvtot)) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s161"><Data ss:Type="Number">' + AllTrim(Str(_nReal_Litro )) + '</Data></Cell>')
				aAdd( _axml, '    <Cell ss:StyleID="s162"><Data ss:Type="Number">' + AllTrim(Str(_nUSS_Litro  )) + '</Data></Cell>')
				aAdd( _axml, '   </Row>')				
			EndIf
			
			_nI++
			
			If AllTrim(_aze0[_nI][13]) != "5"
				_nqtot := _aze0[_nI][10]
				_nvtot := _aze0[_nI][11]
				_nsubtot 	+=	_aze0[_nI][11]
				_nsubtot2 	+=	_aze0[_nI][11]
			Else
				_nqtot := _aze0[_nI][10]
				_nvtot := _aze0[_nI][11]
			EndIf
			
			_np2v := 0
		EndIf
	EndIf
Next

//Ultima linha antes dos totais gerais
If _np2v < 1
	_nI := Len(_aze0)
	_ccod := _aze0[_nI][04]
	_cdesc := _aze0[_nI][05]
	_lsub := .T.
	
	If Len(_asubs) > 0
		_nporce := (_asubs[Len(_asubs)] /_ntotger) * 100
	Else
		_nporce := 0
	EndIf

	If _cdesc == "CUSTO FILIAIS" .And. (_lGera4Pla .Or. _lGera2Pla)// .Or. _lGera1Pla)
		_aCusto04[2,2]:=_ntotlei
		_aCusto04[2,3]:=_nvtot
		_aCusto04[2,4]:=_nvtot / _ntotlei
	EndIf

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s153"><Data ss:Type="String">' + _aze0[_nI][09] + ' - ' + transform( _nporce, "@E 999.99%")   +  '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s156"><Data ss:Type="String">' + _ccod   + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s157"><Data ss:Type="String">' + _cdesc + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_nqtot)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s159"><Data ss:Type="Number">' + AllTrim(Str((_nvtot/_nqtot))) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s160"><Data ss:Type="Number">' + AllTrim(Str(_nvtot)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s161"><Data ss:Type="Number">' + AllTrim(Str(_nvtot / _ntotlei )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s162"><Data ss:Type="Number">' + AllTrim(Str(_nvtot / ( _ntotlei * _nTotdol ))) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s116"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s64"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s140"><Data ss:Type="String">Sub-Total.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s141"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s142"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s143"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / _ntotlei)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s144"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / ( _ntotlei * _nTotdol ))) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s146"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s147"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '   </Row>')
EndIf

//Ultimo subtotal antes dos totais gerais
If !(_lsub) 
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s116"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s64"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s140"><Data ss:Type="String">Sub-Total.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s141"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s142"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s143"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / _ntotlei)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s144"><Data ss:Type="Number">' + AllTrim(Str(_nsubtot / ( _ntotlei * _nTotdol ))) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s146"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s145"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s147"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s148"/>')
	aAdd( _axml, '   </Row>')
EndIf

//Total acumulado
aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">TOTAL ACUMULADO.:</Data></Cell>')
aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
aAdd( _axml, '    <Cell ss:StyleID="s253"/>')

If _cTitulo = "CUSTO OPERACIONAL" .And. xFilial("ZL6") = "10"
   aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_ntotlei+_nTotSoro)) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _ntotger )) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _ntotger /   (_ntotlei+_nTotSoro) )) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _ntotger / ( (_ntotlei+_nTotSoro) * _nTotdol ) )) + '</Data></Cell>')
Else
   aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str(_ntotlei)) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _nsubtot2 )) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _nsubtot2 / _ntotlei )) + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _nsubtot2 / ( _ntotlei * _nTotdol ) )) + '</Data></Cell>')
EndIf

aAdd( _axml, '   </Row>')
aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
aAdd( _axml, '   </Row>')

//Custos totalizadores
For _nI := 1 To Len(_aze0)
	If AllTrim(_aze0[_nI][13]) == "3"
		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
		aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">' + _aze0[_nI][07]   + '</Data></Cell>')//TOTAL  CUSTO OPERACIONAL
		aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str( _aze0[_nI][11] / _ntotger ))   + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aze0[_nI][11] ))   + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aze0[_nI][11] / _ntotlei ))   + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aze0[_nI][11] / ( _ntotlei * _nTotdol )  ))   + '</Data></Cell>')
		aAdd( _axml, '   </Row>')

		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
		aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '   </Row>')
	EndIf
Next

// Faz linhas de estoque anterior, entradas por transferencia, entradas por devolucao
_cSegUni:="N"
_cEstAnt:="1"
_cGrpCus:=""
_cLocais:=""
_cCUF2UM:="N"
_cFilis  :=""
_cProduto:=""
_cCliente:=""
If SubStr(_ctitulo,1,17) == "PRODUTOS ACABADOS"
	_nVlrIcm :=_nVIcmEst:=_nVIcmInt:=_nVIcmTrs:=_nDifAlq:=0//Variaveis antigas
    _nICMSEst :=_nICMSInt:=_nICMSTrs:=0//Variaveis novas valores medio
    nDespEst := nOprsEst:=0//Variaveis novas percentual
    nDespInt := nOprsInt:=0//Variaveis novas percentual
    nDespTrs := nOprsTrs:=0//Variaveis novas percentual
    _cChave  := xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            "

    MEST9ICMS("CARGA_VARIAVEIS_ICMS",_cChave)

    _cProduto:= Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_CODPRO")
    _cGrpCus := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_GRPCUS")
	_cFilis  := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_FILIS")
	_cCliente:= Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_CLIENTE")
    _cSegUni := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_TUNID")
    _cEstAnt := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_ESTANT")
    _cLocais := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_LOCAL")
    _cCUF2UM := Posicione("ZL6",8,xFilial("ZL6")+_aze2[1][17]+PadR(_aze2[1][3],60)+PadR(_aze2[1][16],40)+"PRODUTOS ACABADOS PRODUZIDOS            ","ZL6_CUF2UM")
	_cZE0Chave:=_cGrpCus+_aze2[1][2]+"999992"+"9991  "
                      //_cproduto           ,_cSegUni,_cEstAnt,_cGrpCus,_lPorItem,_cLocal,_cChave	
	_aval := MEST009SB9(AllTrim(_cproduto)  ,_cSegUni,_cEstAnt,_cGrpCus,         ,       ,_cZE0Chave)//valores de estoque anterior
	_aven := MEST009SD1(AllTrim(_cproduto),2,_cSegUni)           //valores de entradas em transferência
    _aven[1][1]+=_aSomaEntTrans[1]	//COMPRAS DE TERCEIROS
    _aven[1][2]+=_aSomaEntTrans[2]	//COMPRAS DE TERCEIROS
	_avdv := MEST009SD1(AllTrim(_cproduto),1,_cSegUni)           //valores de entradas em devolução
	_nDev := (_nsubtot2 + _aval[1][2])/(_aval[1][1] + _ntotlei)
	_nSldAtu := MEST9BscSB2(AllTrim(_cproduto))        //Quantidade atual em estoque

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ESTOQUE ANTERIOR.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str( _aval[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aval[1][2] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aval[1][2] / _aval[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aval[1][2] / _aval[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ENTRADAS DEVOLUCAO.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str( _avdv[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _avdv[1][1] * _nDev )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _avdv[1][1] * _nDev / _avdv[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _avdv[1][1] * _nDev / _avdv[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ENTRADAS TRANSFERENCIA / COMPRAS TERC:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str( _aven[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aven[1][1] * _nDev )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aven[1][1] * _nDev / _aven[1][1]  )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aven[1][1] * _nDev / _aven[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ESTOQUE ATUAL.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _nSldAtu )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">'+ AllTrim(Str( _nSldAtu *_nDev)) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nSldAtu * _nDev / _nSldAtu )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">'+ AllTrim(Str( _nSldAtu * _nDev / _nSldAtu / _nTotdol )) +'</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')

	// Faz linhas dos custos de expedição
    _aExp := MEST009EXP(AllTrim(_cproduto),_cSegUni,_cLocais)  //Quantidade expedida
    _aFret:= MEST009FRT(AllTrim(_cproduto),_aExp[1][1])           //Valor Frete
    _nExp := ((_aExp[1][1] ) * ( _nDev ))
    _nExpD := ((_aExp[1][2] ) * ( _nDev ))
    _nExpF := ((_aExp[1][3] ) * ( _nDev ))
    _nExpT := ((_aExp[1][4] ) * ( _nDev ))

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">EXPEDIDO ESTADUAL.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][2] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' +AllTrim(Str (_nExpD)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _nExpD / _aExp[1][2] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _nExpD / _aExp[1][2] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">EXPEDIDO INTERESTADUAL.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][3] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' +AllTrim(Str (_nExpF)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _nExpF / _aExp[1][3] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _nExpF / _aExp[1][3] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">TRANSFERENCIA.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][4] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' +AllTrim(Str (_nExpT)) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _nExpT / _aExp[1][4] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _nExpT / _aExp[1][4] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">FRETE.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][1] )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][2] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][2] / _aExp[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][2] / _aExp[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">SEGURO.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][1] )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][3] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][3] / _aExp[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][3] / _aExp[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">CHEP.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][1] )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][4] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][4] / _aExp[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][4] / _aExp[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">OCORRENCIAS.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][1] )) +'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][5] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][5] / _aExp[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aFret[1][5] / _aExp[1][1] / _nTotdol )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')

	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')

	// Faz linhas dos  Impostos (ICMS, ICMS ST, PIS/COFINS, IRPJ/CSSL/Parc. IPI)
	_aicst 	:= MEST009IST(AllTrim(_cproduto))  //valores icms st

    If _nICMSEst > 0 .And. nDespEst > 0
       _nVIcmEst:=(_nVIcmEst*_aExp[1][2])
    EndIf
    If _nICMSInt > 0 .And. nDespInt > 0
       _nVIcmInt:=(_nVIcmInt*_aExp[1][3])
    EndIf
    If _nICMSTrs > 0 .And. nDespTrs > 0
       _nVIcmTrs:=(_nVIcmTrs*_aExp[1][4])
    EndIf
	_nVlrIcm:= _nVIcmEst + _nVIcmInt + _nVIcmTrs
	
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ICMS Normal - ESTADUAL.:</Data></Cell>') // A
	aAdd( _axml, '    <Cell ss:StyleID="s252"><Data ss:Type="String">'+TRANSFORM( Round(nDespEst/nOprsEst*100,2), "@E 999.99%")+' </Data></Cell>')//B
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')//C
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][2]) ) + '</Data></Cell>')//D
	aAdd( _axml, '    <Cell ss:StyleID="s255"><Data ss:Type="Number">'+ AllTrim(Str( _nICMSEst ) ) + '</Data></Cell>')//E  
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmEst))+'</Data></Cell>')//F
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmEst /_aExp[1][2]))+'</Data></Cell>') //G
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmEst /_aExp[1][2] / _nTotdol))+'</Data></Cell>') //H
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ICMS Normal - INTERESTADUAL.:</Data></Cell>')//A
	aAdd( _axml, '    <Cell ss:StyleID="s252"><Data ss:Type="String">'+TRANSFORM( Round(nDespInt/nOprsInt*100,2), "@E 999.99%")+' </Data></Cell>')//B
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')//D
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][3]) ) + '</Data></Cell>')//D
	aAdd( _axml, '    <Cell ss:StyleID="s255"><Data ss:Type="Number">'+ AllTrim(Str( _nICMSInt ) ) + '</Data></Cell>')//E
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmInt))+'</Data></Cell>')//F
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmInt /_aExp[1][3]))+'</Data></Cell>') //G
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmInt /_aExp[1][3] / _nTotdol))+'</Data></Cell>') //H
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ICMS Normal - TRANSFERENCIA.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"><Data ss:Type="String">'+TRANSFORM( Round(nDespTrs/nOprsTrs*100,2), "@E 999.99%")+' </Data></Cell>')//B
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')//C
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][4]) ) + '</Data></Cell>')//D
	aAdd( _axml, '    <Cell ss:StyleID="s255"><Data ss:Type="Number">'+ AllTrim(Str( _nICMSTrs ) ) + '</Data></Cell>')//E
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmTrs))+'</Data></Cell>')//F
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmTrs /_aExp[1][4]))+'</Data></Cell>') //G
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">'+ AllTrim(Str( _nVIcmTrs /_aExp[1][4] / _nTotdol))+'</Data></Cell>') //H
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ICMS Dif. de Aliquotas.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">'+ AllTrim(Str( _aExp[1][1]) )+'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">'+ AllTrim(Str( _nDifAlq))+'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nDifAlq /_aExp[1][1]))+'</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">'+ AllTrim(Str( _nDifAlq /_aExp[1][1] / _nTotdol))+'</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">ICMS Substituicao Tributaria.:</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	If _aicst[1][1] > 0
		aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number">' + AllTrim(Str( _aExp[1][1] )) + '</Data></Cell>')
	Else
		aAdd( _axml, '    <Cell ss:StyleID="s158"><Data ss:Type="Number"></Data></Cell>')
	EndIf		
	aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s256"><Data ss:Type="Number">' + AllTrim(Str( _aicst[1][1] )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">' + AllTrim(Str( _aicst[1][1] /  _aExp[1][1]  )) + '</Data></Cell>')
	aAdd( _axml, '    <Cell ss:StyleID="s258"><Data ss:Type="Number">' + AllTrim(Str( _aicst[1][1] /  _aExp[1][1] / _nTotdol  )) + '</Data></Cell>')
	aAdd( _axml, '   </Row>')
	aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
	aAdd( _axml, '   </Row>')
EndIf	

//Total Geral

//Ajusta total de acordo com quadro de entradas e estoque anterior
_aval := MEST009SB9(AllTrim(_cproduto),_cSegUni,_cEstAnt,_cGrpCus)//valores de estoque anterior
_aven := MEST009SD1(AllTrim(_cproduto),2,_cSegUni)         	//valores de entradas em transferência
_avdv := MEST009SD1(AllTrim(_cproduto),1,_cSegUni)         	//valores de entradas em devolução
_aicst:= MEST009IST(AllTrim(_cproduto))             		//valores icms st
_aExp := MEST009EXP(AllTrim(_cproduto),_cSegUni,_cLocais)  	//Quantidade expedida
_aFret:= MEST009FRT(AllTrim(_cproduto),_aExp[1][1])         //Valor Frete

_nDev := (_nsubtot2 + _aval[1][2])/(_aval[1][1] + _ntotlei)
_nExp := ((_aExp[1][1] ) * ( _nDev ))

_cUnidadeinvertida:=""
If SubStr(_ctitulo,1,17) == "PRODUTOS ACABADOS"
	_ntotlei := _aExp[1][1]
	_ntotger := _nExp + _aFret[1][1] + _aicst[1][1] + _nVlrIcm

    MEST9Calc2UN("S",_nTotlei,_cProduto)//Posiciona no SB1 por isso executa sempre
	If _cSegUni = "S"
       _cUnidadeinvertida:=" ("+SB1->B1_SEGUM+")"
	Else
	   _cUnidadeinvertida:=" ("+SB1->B1_UM+")"
	EndIf
EndIf	

If  _cTitulo = "CUSTO OPERACIONAL" .And. xFilial("ZL6") = "10"
   aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
   aAdd( _axml, '    <Cell ss:StyleID="s264"><Data ss:Type="String">TOTAL  '+ _ctitulo + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s265"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s266"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s267"><Data ss:Type="Number">' + AllTrim(Str(_ntotlei+_nTotSoro))    +'</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s268"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s269"><Data ss:Type="Number">' + AllTrim(Str(_ntotger))   + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s270"><Data ss:Type="Number">' + AllTrim(Str(_ntotger /   (_ntotlei+_nTotSoro) ))    + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s271"><Data ss:Type="Number">' + AllTrim(Str(_ntotger / ( (_ntotlei+_nTotSoro) * _nTotdol ) ))  + '</Data></Cell>')
   aAdd( _axml, '   </Row>')

   If _lMostraSoro 
      aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
      aAdd( _axml, '    <Cell ss:StyleID="s264"><Data ss:Type="String">TOTAL CUSTO OPERACIONAL LEITE/QUEIJO/LEITE EM PO/MANTEIGA</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s265"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s266"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s267"><Data ss:Type="Number">' + AllTrim(Str(_ntotlei))    +'</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s268"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s269"><Data ss:Type="Number">' + AllTrim(Str( _ntotger-(_ntotger/4)))   + '</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s270"><Data ss:Type="Number">' + AllTrim(Str((_ntotger-(_ntotger/4)) / (_ntotlei) ))    + '</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s271"><Data ss:Type="Number">' + AllTrim(Str((_ntotger-(_ntotger/4)) / ( (_ntotlei) * _nTotdol ) ))  + '</Data></Cell>')
      aAdd( _axml, '   </Row>')
   
      aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
      aAdd( _axml, '    <Cell ss:StyleID="s264"><Data ss:Type="String">TOTAL CUSTO OPERACIONAL SORO EM PO</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s265"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s266"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s267"><Data ss:Type="Number">' + AllTrim(Str(_nTotSoro))    +'</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s268"/>')
      aAdd( _axml, '    <Cell ss:StyleID="s269"><Data ss:Type="Number">' + AllTrim(Str(_ntotger/4))   + '</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s270"><Data ss:Type="Number">' + AllTrim(Str((_ntotger/4) / _nTotSoro ))    + '</Data></Cell>')
      aAdd( _axml, '    <Cell ss:StyleID="s271"><Data ss:Type="Number">' + AllTrim(Str((_ntotger/4) / ( _nTotSoro * _nTotdol ) ))  + '</Data></Cell>')
      aAdd( _axml, '   </Row>')
   EndIf
Else
   aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
   aAdd( _axml, '    <Cell ss:StyleID="s264"><Data ss:Type="String">TOTAL  '+ _ctitulo +_cUnidadeinvertida+ '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s265"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s266"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s267"><Data ss:Type="Number">' + AllTrim(Str(_ntotlei))    +'</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s268"/>')
   aAdd( _axml, '    <Cell ss:StyleID="s269"><Data ss:Type="Number">' + AllTrim(Str(_ntotger))   + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s270"><Data ss:Type="Number">' + AllTrim(Str(_ntotger / _ntotlei ))    + '</Data></Cell>')
   aAdd( _axml, '    <Cell ss:StyleID="s271"><Data ss:Type="Number">' + AllTrim(Str(_ntotger / ( _ntotlei * _nTotdol ) ))  + '</Data></Cell>')
   aAdd( _axml, '   </Row>')

   For nPos := 1 To Len(_aRecalVlrs)
	   If _aRecalVlrs[nPos,1] $ AllTrim(_ctitulo2)
          _aRecalVlrs[nPos,3] := (_ntotger / _ntotlei)//P. R$(P/LT )
	   EndIf
   Next
	
	If _cCUF2UM = "1"
	    _nTotleInv:=MEST9Calc2UN("S",_nTotlei,_cProduto)//Posiciona no SB1 por isso executa sempre
	    _cUnidadeinvertida:=" ("+SB1->B1_SEGUM+")"
		If _cSegUni = "S"//Se o de cima foi segunda pega a primeira unidade para segunda linha
		   _nTotleInv:=_aExp[1][5]
		   _cUnidadeinvertida:=" ("+SB1->B1_UM+")"
		EndIf
	    //PULA LINHA
		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
		aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '   </Row>')
	    //PULA LINHA
		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
		aAdd( _axml, '    <Cell ss:StyleID="s264"><Data ss:Type="String">TOTAL '+ _ctitulo+_cUnidadeinvertida + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s265"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s266"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s267"><Data ss:Type="Number">' + AllTrim(Str(_nTotleInv))    +'</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s268"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s269"><Data ss:Type="Number">' + AllTrim(Str(_ntotger))   + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s270"><Data ss:Type="Number">' + AllTrim(Str(_ntotger / _nTotleInv ))    + '</Data></Cell>')
		aAdd( _axml, '    <Cell ss:StyleID="s271"><Data ss:Type="Number">' + AllTrim(Str(_ntotger / ( _nTotleInv * _nTotdol ) ))  + '</Data></Cell>')
		aAdd( _axml, '   </Row>')
    EndIf

    If _cTitulo <> "CUSTO OPERACIONAL" 
	    //PULA LINHA
		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
		aAdd( _axml, '    <Cell ss:StyleID="s163"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s71"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s84"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s164"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s165"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s166"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '    <Cell ss:StyleID="s167"/>')
		aAdd( _axml, '   </Row>')
        
		_nPrecoMedio:=MEST9PMedio(_cFilis,_cProduto,_cCliente)
	    
		aAdd( _axml, '   <Row ss:AutoFitHeight="0">')
	    aAdd( _axml, '    <Cell ss:StyleID="s251"><Data ss:Type="String">PRECO MEDIO DE VENDA</Data></Cell>')
	    aAdd( _axml, '    <Cell ss:StyleID="s252"/>')
	    aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	    aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	    aAdd( _axml, '    <Cell ss:StyleID="s255"/>')
	    aAdd( _axml, '    <Cell ss:StyleID="s253"/>')
	    aAdd( _axml, '    <Cell ss:StyleID="s257"><Data ss:Type="Number">'+ AllTrim(Str( _nPrecoMedio ))+'</Data></Cell>')
  	    aAdd( _axml, '    <Cell ss:StyleID="s258"/>')
	    aAdd( _axml, '   </Row>')
	EndIf
EndIf

If _lGera4Pla .Or. _lGera2Pla //.OR. _lGera1Pla
	If _ctitulo = "CUSTO OPERACIONAL"
		_aCusto04[1,2]:=_ntotlei
		_aCusto04[1,3]:=_ntotger
		_aCusto04[1,4]:=_ntotger / _ntotlei
	Else
		aAdd(_aCusto04,{SubStr(_ctitulo,21),_ntotlei,_ntotger, (_ntotger / _ntotlei) })
	EndIf
EndIf

_cTesteA:=StrTran(_cTesteA,".",",")
_cFileNome:=_cdir+"MEST009_REDIMENTO_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".CSV"
MemoWrite(_cFileNome,_cTesteA)

Return _axml

/*
===============================================================================================================================
Programa----------: MEST009E3
Autor-------------: Josue Danich Prestes
Data da Criacao---: 23/11/2015
Descricao---------: Fecha arquivo Excel
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST009E3()

Local _axml := {}

aAdd( _axml, '  </Table>')
aAdd( _axml, '  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">')
aAdd( _axml, '   <PageSetup>')
aAdd( _axml, '    <Header x:Margin="0.31496062000000002"/>')
aAdd( _axml, '    <Footer x:Margin="0.31496062000000002"/>')
aAdd( _axml, '    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.511811024"')
aAdd( _axml, '     x:Right="0.511811024" x:Top="0.78740157499999996"/>')
aAdd( _axml, '   </PageSetup>')
aAdd( _axml, '   <Unsynced/>')
aAdd( _axml, '   <Zoom>85</Zoom>')
aAdd( _axml, '   <Selected/>')
aAdd( _axml, '   <Panes>')
aAdd( _axml, '    <Pane>')
aAdd( _axml, '     <Number>3</Number>')
aAdd( _axml, '     <ActiveRow>4</ActiveRow>')
aAdd( _axml, '     <ActiveCol>8</ActiveCol>')
aAdd( _axml, '    </Pane>')
aAdd( _axml, '   </Panes>')
aAdd( _axml, '   <ProtectObjects>False</ProtectObjects>')
aAdd( _axml, '   <ProtectScenarios>False</ProtectScenarios>')
aAdd( _axml, '  </WorksheetOptions>')
aAdd( _axml, ' </Worksheet>')
aAdd( _axml, '</Workbook>')

Return _axml

/*
===============================================================================================================================
Programa----------: MEST009E1
Autor-------------: Josue Danich Prestes
Data da Criacao---: 16/11/2015
Descricao---------: Monta cabecalho do excel
Parametros--------:
Retorno-----------:
===============================================================================================================================
*/
Static Function MEST009E1()

Local _axml  := {}
Local _cArq01:= "\data\italac\mest009\MEST009_PLAN_01.txt"
Local _lTXT  := FILE(_cArq01)

If _lTXT
	If FT_FUSE(_cArq01) == -1
		U_ITMsg("Não foi possível abrir o arquivo: "+_cArq01 , "Arquivo inválido" , "Favor verificar se o arquivo se esta correto.",1)
		Return _axml
	EndIf
	
	FT_FGOTOP()//PONTO NO TOPO
	
	If FT_FLASTREC() == 0 
		U_ITMsg("O arquivo "+_cArq01+" não possui dados." , "Arquivo inválido" , "Favor verificar se o arquivo se esta correto.",1)
		Return _axml
	EndIf
	
	While !FT_FEof()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
		_cLinha:=FT_FREADLN()
		If !Empty(_cLinha)
			aAdd(_axml,AllTrim(_cLinha))
		EndIf
		FT_FSKIP()   //próximo registro no arquivo txt
	EndDo
	
	FT_FUSE()//Fecha o arquivo
EndIf

Return _axml

/*
===============================================================================================================================
Programa----------: MEST009SB9
Autor-------------: Josue Danich Prestes
Data da Criacao---: 22/03/2016
Descricao---------: Retorna quantidade e valor de estoque anterior de um produto
Parametros--------: _cproduto,_cSegUni,_cEstAnt,_cGrpCus,_lPorItem,_cLocal,_cChave
Retorno-----------: _aval - array com quantidade e valor de estoque anterior
===============================================================================================================================
*/
Static Function MEST009SB9(_cproduto,_cSegUni,_cEstAnt,_cGrpCus,_lPorItem,_cLocal,_cChave)

Local _aval 	:= {}
Local _cQuery 	:= ""
Local _dFim		:= MV_PAR06
Local _aSaldos	:= {} , _xi , _vl , _ji , _zi , _ii 
Local _aItem	:= {}
Local _aLocal	:= {}
Local _atrab	:= {}
Local _nQtde	:= 0
Local _nValor	:= 0
Local _nExpe	:= 0
Local _nVlr		:= 0
Local _aFilial	:= {}
Local _aTotItem := {}
Local _cFilGuard:= cFilant

Default _cLocal	  := "03;20;21;22;30;31;32;33;34;40;04;07;50;52"
Default _lPorItem := .F.
Default _cChave   := ""

_dfim:= LastDate(MonthSub(_dfim,1))

If _cEstAnt = "2" // ZL6_ESTANT = "2=Fechamanto Anterior (ZE0)"
   _cMes:=Val(SubStr(DToS(MV_PAR05),5,2))
   If _cMes = 1//Janeiro
      _cMes:="12"+Str( Val(SubStr(DToS(MV_PAR05),1,4)) - 1 , 4)
   Else
      _cMes:=StrZero( _cMes - 1 , 2) + SubStr(DToS(MV_PAR05),1,4)
   EndIf

	If "08000000064" $ _cproduto  .Or. "08000000007"  $ _cproduto//_nExpe == 0 .And. _nVlr == 0
		_cQuery := " SELECT ZE0_QTDE, ZE0_VALOR FROM "+ RETSQLNAME("ZE0")+" ZE0 "
		_cQuery += " WHERE ZE0.D_E_L_E_T_ = ' ' AND "
		_cQuery += "       ZE0_FILIAL = '"+cFilant+"' AND "
		_cQuery += "       ZE0_DSECT  = 'ESTOQUE ATUAL' AND "
		_cQuery += "       ZE0_DGRPCT = 'CREME DE LEITE A GRANEL' AND "
		_cQuery += "       ZE0_DATARQ = '"+_cMes+"' "

		MPSysOpenQuery( _cQuery, "ZE0T" ) 

		If .NOT. ZE0T->( Eof() )
			_nExpe   += ZE0T->ZE0_QTDE
			_nVlr    += ZE0T->ZE0_VALOR
		EndIf
		ZE0T->( DBCloseArea() )

		aAdd(_aTotItem,{"",0,0})	
		aAdd(_aval,{ _nExpe , _nVlr   })	

		If _lPorItem
			Return _aTotItem
		Else
			Return _aval
		EndIf
    EndIf	

	_aItem 	:= StrTokArr(AllTrim(_cproduto), ';')

	ZE0->(DBSetOrder(1))
	If !Empty(_cChave) .And. ZE0->(DBSeek(xFilial("ZE1")+_cMes+_cChave))
		_nExpe:= ZE0->ZE0_QTDE
		_nVlr := ZE0->ZE0_VALOR
		_aItem:={}
	EndIf

	ZE1->( DBSetOrder(1) )
	For _vl := 1 To Len(_aItem)
		_cSeek := xFilial("ZE1") + _cMes + "    " + _aItem[_vl]
		If ZE1->( DBSeek( _cSeek ) )
			_nExpe   += ZE1->ZE1_ESTATU
			_nVlr    += ZE1->ZE1_VESTAT//(ZE1->ZE1_CUSTOP/ZE1->ZE1_EXPE)*ZE1->ZE1_ESTATU

			If (_nPos:=aScan(_aTotItem,{|I| I[1] == _aItem[_vl] } )) = 0
				aAdd(_aTotItem,{_aItem[_vl],ZE1->ZE1_VESTAT,ZE1->ZE1_CUSTOP })
			Else
				_aTotItem[_nPos,2]+=ZE1->ZE1_VESTAT
				_aTotItem[_nPos,3]+=ZE1->ZE1_CUSTOP
			EndIf	
		EndIf
	Next

	If Len(_aTotItem) = 0
		aAdd(_aTotItem,{"",0,0})	
	EndIf
	aAdd(_aval,{ _nExpe , _nVlr   })	
ElseIf xFilial("SB9") == "92" .And. !Empty(_cproduto) .And. !Empty(_cfilis)
	_aFilial := StrTokArr(AllTrim(_cfilis), ';')
	_aItem 	:= StrTokArr(AllTrim(_cproduto), ';')
	_aLocal	:= StrTokArr(AllTrim(_cLocal), ';')

	For _xi := 1 To Len(_aItem)   
		For _ii:= 1 To Len(_aLocal)
			If !Empty(_cfilis)
				For _ji := 1 To Len(_aFilial)
					aAdd(_atrab,{_aitem[_xi],_alocal[_ii], _aFilial[_ji]})
				Next		
			Else	
				aAdd(_atrab,{_aitem[_xi],_alocal[_ii]})
			EndIf
		Next	
	Next
	For _zi := 1 To Len(_atrab)
		If !Empty(_cFilis)
            cFilant:=_atrab[_zi,3]
			_aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1, _atrab[_zi,3] ) //obtém o saldo final em estoque na data informada
		EndIf
		_nQtde	+= _asaldos[1]
		_nValor += _asaldos[2]

        If (_nPos:=aScan(_aTotItem,{|I| I[1] == _atrab[_zi,1] } )) = 0
           aAdd(_aTotItem,{_atrab[_zi,1],_asaldos[1] , _asaldos[2] })
       	Else
           _aTotItem[_nPos,2]+=_asaldos[1]
           _aTotItem[_nPos,3]+=_asaldos[2]
        EndIf	
	Next	

	aAdd(_aval,{ MEST9Calc2UN(_cSegUni,_nQtde,_cProduto) ,_nValor})		
ElseIf !Empty(_cproduto)
	_aItem 	:= StrTokArr(AllTrim(_cproduto), ';')
	_aLocal	:= StrTokArr(AllTrim(_cLocal), ';')

	If MV_PAR07 <> 2
		If !Empty(_cfilis)
			_aFilial := StrTokArr(AllTrim(_cfilis), ';')
		EndIf			
	EndIf	
	For _xi := 1 To Len(_aItem)   
		For _ii:= 1 To Len(_aLocal)
			If MV_PAR07 <> 2
				If !Empty(_cfilis)
					For _ji := 1 To Len(_aFilial)
						aAdd(_atrab,{_aitem[_xi],_alocal[_ii], _aFilial[_ji]})
					Next		
				Else	
					aAdd(_atrab,{_aitem[_xi],_alocal[_ii]})
				EndIf
			Else
				aAdd(_atrab,{_aitem[_xi],_alocal[_ii]})
			EndIf		
		Next	
	Next
	For _zi := 1 To Len(_atrab)
		If MV_PAR07 <> 2
			If !Empty(_cFilis)
               cFilant:=_atrab[_zi,3]
			   _aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1, _atrab[_zi,3] ) //obtém o saldo final em estoque na data informada
			Else
			   _aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1 ) //obtém o saldo final em estoque na data informada	
			EndIf
		Else
			_aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1 ) //obtém o saldo final em estoque na data informada	
		EndIf			
        If _cSegUni = "S"
           _nSldItem:= _asaldos[7]
        Else
           _nSldItem:= _asaldos[1]
      	EndIf
		_nQtde	+= _nSldItem
		_nValor += _asaldos[2]

        If (_nPos:=aScan(_aTotItem,{|I| I[1] == _atrab[_zi,1] } )) = 0
           aAdd(_aTotItem,{_atrab[_zi,1],_nSldItem , _asaldos[2] })
       	Else
           _aTotItem[_nPos,2]+=_nSldItem
           _aTotItem[_nPos,3]+=_asaldos[2]
        EndIf	
	Next	
	aAdd(_aval,{ _nQtde , _nValor })	
Else
	aAdd(_aval,{0,0})	
	aAdd(_aTotItem,{"",0,0})	
EndIf

cFilant:=_cFilGuard

If _lPorItem
	Return _aTotItem
Else
	Return _aval
EndIf

/*
===============================================================================================================================
Programa----------: MEST009SD1
Autor-------------: Josue Danich Prestes
Data da Criacao---: 22/03/2016
Descricao---------: Retorna quantidade e valor de estoque por entrada de devolução ou transferência
Parametros--------: _cproduto - código do produto
Retorno-----------: _aval - array com quantidade e valor de entrada por devolução e transferência
===============================================================================================================================
*/
Static Function MEST009SD1(_cproduto,_ntipo,_cSegUni)

Local _aval := {}
Local _cQuery := ""

_cQuery := " SELECT SUM(D1_QUANT) QTDE, SUM(D1_CUSTO) VALOR FROM " + RETSQLNAME("SD1") + " SD1"
_cQuery += " JOIN " + RETSQLNAME("SF4") + " SF4 ON D1_TES = F4_CODIGO AND D1_FILIAL = F4_FILIAL "
_cQuery += " WHERE SD1.D_E_L_E_T_ = ' ' "
_cQuery += " AND D1_DTDIGIT BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += " AND D1_TES > ' ' "
                         
If !Empty(_cproduto)
	If xFilial("SD1") = "92"
		If MV_PAR07 <> 2
			If Empty(_cFilis)
				_cQuery += " AND D1_FILIAL = '" + xFilial("SD1") + "'"
			Else
				_cQuery += " AND D1_FILIAL IN " +  FormatIn(AllTrim(_cFilis),";") 
			EndIf
		Else
			_cQuery += " AND D1_FILIAL = '" + xFilial("SD1") + "'"		
		EndIf	
	Else
		_cQuery += " AND D1_FILIAL = '" + xFilial("SD1") + "'"		
	EndIf	
EndIf	

_cQuery += " AND D1_COD IN " + FormatIn(AllTrim(_cproduto),";") + ""
_cQuery += " AND F4_ESTOQUE = 'S' "

If _ntipo == 1 //Notas de devolução
  _cQuery += " AND D1_LOCAL IN ('31','03') "  
ElseIf _ntipo == 2 //Outras notas
	_cQuery += " AND (SELECT F1_TIPO FROM " +  retsqlname("SF1") + " SF1 WHERE SF1.D_E_L_E_T_ = ' '"
	_cQuery += "      AND F1_FILIAL = D1_FILIAL AND F1_DOC = D1_DOC AND F1_SERIE = D1_SERIE
	_cQuery += "      AND F1_FORNECE = D1_FORNECE AND F1_LOJA = D1_LOJA AND ROWNUM = 1) <> 'D'"
	_cQuery += " AND D1_LOCAL IN ('20','22') AND D1_FORNECE = 'F00001' "  
EndIf

_cQuery += " GROUP BY D1_FILIAL"

MPSysOpenQuery( _cQuery ,"SD1T" ) 
DBSelectArea("SD1T")

If !SD1T->( Eof() )
	aAdd(_aval,{ MEST9Calc2UN(_cSegUni,SD1T->QTDE,_cProduto) , SD1T->VALOR })
Else
	aAdd(_aval,{0,0})
EndIf

SD1T->( DBCloseArea() )
	
Return _aval

/*
===============================================================================================================================
Programa----------: MEST009IST
Autor-------------: Andre Lisboa
Data da Criacao---: 08/04/2016
Descricao---------: Retorna valor do ICMS ST para o produto
Parametros--------: _cproduto - código do produto
Retorno-----------: _aval - array valor total do ICMS ST
===============================================================================================================================
*/
Static Function MEST009IST(_cproduto)

Local _aicst := {}
Local _cQuery := ""

_cQuery := "SELECT Case WHEN D.ICMSRET > 0 THEN V.TOTAL - D.ICMSRET Else V.TOTAL END AS TOTAL,"
_cQuery += "                                                          V.QUANT AS QUANT"
_cQuery += " FROM  (SELECT D2_FILIAL, SUM(D2_VALBRUT) - SUM(D2_TOTAL) TOTAL,          "
_cQuery += "        (SELECT SUM(D2_QUANT) FROM " + RETSQLNAME("SD2") 
_cQuery += "                WHERE D_E_L_E_T_ = ' '  AND D2_COD IN " + FormatIn(AllTrim(_CPRODUTO),";")
_cQuery += "                  AND D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += "                  AND D2_FILIAL = '" + xFilial("SD2") + "' ) AS QUANT "
_cQuery += "        FROM " + RETSQLNAME("SD2") 
_cQuery += "        WHERE D_E_L_E_T_ = ' '  "
_cQuery += "              AND D2_COD IN " + FormatIn(AllTrim(_CPRODUTO),";")
_cQuery += "              AND D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += "              AND D2_FILIAL = '" + xFilial("SD2") + "'"
_cQuery += "        GROUP BY D2_FILIAL ) V "
_cQuery += "LEFT JOIN "
_cQuery += "     (SELECT  D1_FILIAL, SUM(D1_TOTAL) DEV, SUM(D1_ICMSRET) ICMSRET  "
_cQuery += "              FROM "+ retsqlname("SD1") 
_cQuery += "              WHERE D_E_L_E_T_ = ' ' AND D1_COD IN " + FormatIn(AllTrim(_CPRODUTO),";")
_cQuery += "                AND D1_DTDIGIT BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += "                AND D1_FILIAL = '" + xFilial("SD1") + "'"
_cQuery += "                AND D1_TIPO = 'D' "
_cQuery += "      GROUP BY D1_FILIAL) D  "
_cQuery += "ON V.D2_FILIAL =  D.D1_FILIAL "

MPSysOpenQuery( _cQuery ,"SD2T" ) 
DBSelectArea("SD2T")

If .not. SD2T->( Eof() )
	If SD2T->TOTAL > 0
		aAdd(_aicst,{SD2T->TOTAL,0})
	Else
		aAdd(_aicst,{0,0})
	EndIf
Else
	aAdd(_aicst,{0,0})
EndIf

SD2T->( DBCloseArea() )
	
Return _aicst

/*
===============================================================================================================================
Programa----------: MEST009EXP
Autor-------------: Andre Lisboa
Data da Criacao---: 20/04/2016
Descricao---------: Retorna quantidade expedida
Parametros--------: _cproduto - código do produto
Retorno-----------: _aExp - array quantidade total
===============================================================================================================================
*/
Static Function MEST009EXP(_cproduto,_cSegUni,_cLocais)

Local _aExp := {}
Local _cQuery := ""
Local _cEst := Posicione('SM0',1,cEmpAnt+xFilial("SD2"),'M0_ESTCOB')

If Empty(_cproduto)
   aAdd(_aExp,{0,0,0,0,0})
   Return _aExp
EndIf

_cQuery += " SELECT (DECODE(TMP.DQUANT,NULL,0,TMP.DQUANT)+DECODE(TMP.FQUANT,NULL,0,TMP.FQUANT)+DECODE(T.QUANT,NULL,0,T.QUANT)) AS TOT, "
_cQuery += "        TMP.DQUANT, "
_cQuery += "        TMP.FQUANT, "
_cQuery += "        T.QUANT "
_cQuery += " from "
_cQuery += " (SELECT D.QUANT AS DQUANT, F.QUANT AS FQUANT, D.D2_FILIAL AS FILIAL FROM "
_cQuery += "     (SELECT SUM(D2_QUANT) AS QUANT, D2_FILIAL "
_cQuery += "         from ("+RETSQLNAME("SD2")+" SD2 "
_cQuery += "         JOIN  "+RETSQLNAME("SC5")+" SC5 ON D2_FILIAL = C5_FILIAL AND D2_PEDIDO = C5_NUM) "
_cQuery += "         JOIN  "+RETSQLNAME("SF4")+" SF4 on D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO "
_cQuery += "         where SD2.D_E_L_E_T_ = ' ' and SC5.D_E_L_E_T_ = ' ' and SF4.D_E_L_E_T_ = ' ' "
_cQuery += "         and c5_i_oper <> ' ' "
_cQuery += "         and f4_estoque = 'S' "
If xFilial("SD2") $ ("93/90")
	_cQuery += "         AND D2_LOCAL IN ('20', '21', '22','03','36','42') "
Else
	_cQuery += "         AND D2_LOCAL IN ('20', '21', '22','03') "
EndIf		
_cQuery += "         AND D2_CF <> '5927' "
_cQuery += "         and d2_cod in " + FormatIn(AllTrim(_cproduto),";")
_cQuery += "         and d2_emissao between '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
If !Empty(_cproduto)
	If xFilial("SD2") = "92"
		If MV_PAR07 <> 2
			If Empty(_cFilis)
				_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
			Else
				_cQuery += " AND D2_FILIAL IN " +  FormatIn(AllTrim(_cFilis),";")
			EndIf
		Else
			_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
		EndIf
	Else
		_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
	EndIf
EndIf
_cQuery += "         and d2_est = '" + _cEst + "' "
_cQuery += "         and d2_cliente <> '000001' group by d2_filial) D "    
_cQuery += "   FULL OUTER JOIN "
_cQuery += "     (SELECT SUM(D2_QUANT) AS QUANT, D2_FILIAL  "
_cQuery += "         FROM ("+RETSQLNAME("SD2")+" SD2 "
_cQuery += "         JOIN  "+RETSQLNAME("SC5")+" SC5 ON D2_FILIAL = C5_FILIAL AND D2_PEDIDO = C5_NUM) "
_cQuery += "         JOIN  "+RETSQLNAME("SF4")+" SF4 on D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO "
_cQuery += "            where SD2.D_E_L_E_T_ = ' ' and SC5.D_E_L_E_T_ = ' ' and SF4.D_E_L_E_T_ = ' ' "
_cQuery += "            and c5_i_oper <> ' ' "
_cQuery += "            and f4_estoque = 'S' "
If xFilial("SD2") $ ("93/90")
	_cQuery += "         AND D2_LOCAL IN ('20', '21', '22','03','36','42') "
Else
	_cQuery += "         AND D2_LOCAL IN ('20', '21', '22','03') "
EndIf		
_cQuery += "            AND D2_CF  <> '5927' "
_cQuery += "            and d2_cod in " + FormatIn(AllTrim(_cproduto),";")
_cQuery += "            and d2_emissao between '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
If !Empty(_cproduto)
	If xFilial("SD2") = "92"
		If MV_PAR07 <> 2
			If Empty(_cFilis)
				_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
			Else
				_cQuery += " AND D2_FILIAL IN " +  FormatIn(AllTrim(_cFilis),";")
			EndIf
		Else
			_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
		EndIf
	Else
		_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
	EndIf
EndIf
_cQuery += "            AND D2_EST <> '" + _cEst + "' "
_cQuery += "            AND D2_CLIENTE <> '000001' group by d2_filial) F    "
_cQuery += "            ON D.D2_FILIAL = F.D2_FILIAL ) TMP "
_cQuery += "   FULL OUTER JOIN "
_cQuery += "     (select SUM(D2_QUANT) AS QUANT, D2_FILIAL  "
_cQuery += "         FROM ("+RETSQLNAME("SD2")+" SD2 "
_cQuery += "         JOIN  "+RETSQLNAME("SC5")+" SC5 ON D2_FILIAL = C5_FILIAL AND D2_PEDIDO = C5_NUM) "
_cQuery += "         JOIN  "+RETSQLNAME("SF4")+" SF4 ON D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO "
_cQuery += "            WHERE SD2.D_E_L_E_T_ = ' ' and SC5.D_E_L_E_T_ = ' ' and SF4.D_E_L_E_T_ = ' ' "
_cQuery += "            AND C5_I_OPER <> ' ' "
_cQuery += "            AND F4_ESTOQUE = 'S'  "

If !Empty(AllTrim(_cLocais))
	If xFilial("SD2") $ ("93/90")   
   		_cLocais:="20;21;22;03;36;42"+AllTrim(_cLocais)
   	Else
   		_cLocais:="20;21;22;03;"+AllTrim(_cLocais)	
   	EndIf	
Else
   If xFilial("SD2") $ ("93/90")   
   		_cLocais:="20;21;22;03;36;42"+AllTrim(_cLocais)
   Else		
   		_cLocais:="20;21;22;03"    
   EndIf		
EndIf

_cQuery += "            AND D2_LOCAL IN "+FormatIn(_cLocais,";")//('20', '21', '22')
_cQuery += "            AND D2_CF  <> '5927' "
_cQuery += "            AND D2_COD IN " + FormatIn(AllTrim(_cproduto),";") + ""
_cQuery += "            AND D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
If !Empty(_cproduto)
	If xFilial("SD2") = "92"
		If MV_PAR07 <> 2
			If Empty(_cFilis)
				_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
			Else
				_cQuery += " AND D2_FILIAL IN " +  FormatIn(AllTrim(_cFilis),";")
			EndIf
		Else
			_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
		EndIf
	Else
		_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
	EndIf
EndIf
_cQuery += "            and d2_cliente = '000001' group by d2_filial) T "
_cQuery += " ON TMP.FILIAL = T.D2_FILIAL "

MPSysOpenQuery( _cQuery ,"SD2T" ) 
DBSelectArea("SD2T")

If .not. SD2T->( Eof() )
	aAdd(_aExp,{ MEST9Calc2UN(_cSegUni,SD2T->TOT   ,_cProduto),;//1
	             MEST9Calc2UN(_cSegUni,SD2T->DQUANT,_cProduto),;//2
	             MEST9Calc2UN(_cSegUni,SD2T->FQUANT,_cProduto),;//3
	             MEST9Calc2UN(_cSegUni,SD2T->QUANT ,_cProduto),;//4
	             SD2T->TOT})//5 - Qtde sem conversão
Else
	aAdd(_aExp,{0,0,0,0,0})
EndIf

SD2T->( DBCloseArea() )
	
Return _aExp

/*
===============================================================================================================================
Programa----------: MEST009FRT
Autor-------------: Andre Lisboa
Data da Criacao---: 20/04/2016
Descricao---------: Retorna valor do frete
Parametros--------: _cproduto - código do produto
Retorno-----------: _aFret - array valor total
===============================================================================================================================
*/
Static Function MEST009FRT(_cproduto,_nExp)

Local _aFret := {}//
Local _cQuery    := ""
Local _cquery2   := ""
Local _cqueryp   := ""
Local _cqueryChep:= ""
Local _cqueryOcor:= "" 
Local _nFator    := SuperGetMV( "IT_SEGFRET",.F.,0.0013)
Local _nVlrGrupo := _nVlrGeral := 0
Local _nFatorFret:= SuperGetMV("IT_FAFRVEN",.F.,"0*")
Local _lDividir  := .T.

If "*" $ _nFatorFret
   _lDividir:= .F.
EndIf
_nFatorFret:= Val(_nFatorFret)

//SEGURO
_cquery2 := " SELECT SUM(D2_VALBRUT) AS VLRSEG "
_cquery2 += " FROM "+ RETSQLNAME("SD2")+" SD2 "  
_cquery2 += " JOIN  "+RETSQLNAME("SC5")+" SC5 ON D2_FILIAL = C5_FILIAL AND D2_PEDIDO = C5_NUM "
_cquery2 += " JOIN  "+RETSQLNAME("SF4")+" SF4 on D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO "
_cquery2 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
_cquery2 += "   AND C5_I_OPER <> ' ' "
_cquery2 += "   AND F4_ESTOQUE = 'S' "
_cquery2 += "   AND SD2.D2_LOCAL IN ('20', '21', '22') "
_cquery2 += "   AND SD2.D2_CF  <> '5927' "
If !Empty(_cproduto)
   _cquery2 += "   AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
EndIf   
_cquery2 += "   AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cquery2 += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
_cquery2 += "   AND SD2.D2_TIPO = 'N' AND D2_TP = 'PA'" 
_cTeste:=""
_cTeste+="SEGURO: "+CHR(13)+CHR(10)
_cTeste+=_cquery2+CHR(13)+CHR(10)

MPSysOpenQuery( _cquery2 ,"SD2TX" ) 
DBSelectArea("SD2TX")

_cValores:=""

If .not. SD2TX->( Eof() ) .And. !Empty(_cproduto)
					//1-FRETE SOMADO       ,2-FRETE,3-SEGURO               ,4-CHEP,5-OCORRENCIAS
	aAdd(_aFret,{(SD2TX->VLRSEG*_nFator),0      ,(SD2TX->VLRSEG*_nFator),0     ,0         })
	_nVlrGrupo:=SD2TX->VLRSEG
	_cValores:="SD2TX->VLRSEG: "+Str(SD2TX->VLRSEG,22,7)+CRLF
Else
	aAdd(_aFret,{0,0,0,0,0})
EndIf

SD2TX->( DBCloseArea() )

_cTeste+=_cValores+CRLF

If _nVlrGrupo = 0
   Return _aFret
EndIf

///VALOR TOTAL DE FATURAMENTO DO PRODUTO   * 
_cqueryp := " SELECT SUM(D2_TOTAL) AS VLRTOT "
_cqueryp += " FROM "+ RETSQLNAME("SD2") +" SD2 "
_cqueryp += " JOIN  "+RETSQLNAME("SC5")+" SC5 ON D2_FILIAL = C5_FILIAL AND D2_PEDIDO = C5_NUM "
_cqueryp += " JOIN  "+RETSQLNAME("SF4")+" SF4 on D2_FILIAL = F4_FILIAL AND D2_TES = F4_CODIGO "
_cqueryp += "  WHERE SD2.D_E_L_E_T_ = ' ' AND SC5.D_E_L_E_T_ = ' ' AND SF4.D_E_L_E_T_ = ' ' "
_cqueryp += "   AND C5_I_OPER <> ' ' "
_cqueryp += "   AND F4_ESTOQUE = 'S' "
_cqueryp += "   AND SD2.D2_LOCAL IN ('20', '21', '22') "
_cqueryp += "   AND SD2.D2_CF  <> '5927' "
_cqueryp += "   AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cqueryp += "   AND SD2.D2_CLIENTE <> '000001'   "
_cqueryp += "   AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
_cqueryp += "   AND SD2.D2_TIPO = 'N' AND D2_TP = 'PA' " 

_cTeste+="VALOR TOTAL DE FATURAMENTO DO PRODUTO: "+CHR(13)+CHR(10)
_cTeste+=_cqueryp+CHR(13)+CHR(10)

MPSysOpenQuery( _cqueryp ,"SD2TP" ) 

_cValores:=""
If .not. SD2TP->( Eof() )
   _nVlrGeral:=SD2TP->VLRTOT
    _cValores:="SD2TP->VLRTOT: "+Str(SD2TP->VLRTOT,22,7)+CRLF
EndIf

SD2TP->( DBCloseArea() )

_cTeste+=_cValores+CRLF

/// FRETE A SOMAR
_cQuery := " SELECT SUM(D2_I_FRET) AS FRETE from "+ retsqlname("SD2") "
_cQuery += " WHERE D_E_L_E_T_ = ' ' AND D2_COD IN " + FormatIn(AllTrim(_cproduto),";") + ""
_cQuery += " AND D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"

If !Empty(_cproduto)
   If xFilial("SD2") = "92"
		If Empty(_cFilis)
			_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
		Else
			_cQuery += " AND D2_FILIAL IN " +  FormatIn(AllTrim(_cFilis),";")
		EndIf
   Else
		_cQuery += " AND D2_FILIAL = '" + xFilial("SD2") + "'"
   EndIf
EndIf

_cTeste+="FRETE A SOMAR: "+CHR(13)+CHR(10)
_cTeste+=_cQuery+CHR(13)+CHR(10)
_cValores:=""

MPSysOpenQuery( _cQuery ,"SD2T" ) 

If .NOT. SD2T->( Eof() )
	If _nFatorFret=0 
		_nFrete:=SD2T->FRETE
	ElseIf _lDividir
		_nFrete:=SD2T->FRETE/_nFatorFret
	Else
		_nFrete:=SD2T->FRETE*_nFatorFret
	EndIf   
	//1-FRETE SOMADO,2-FRETE,3-SEGURO,4-CHEP
	_aFret[1,2]+= _nFrete
	_aFret[1,1]+= _nFrete
	_cValores:="_nFatorFret: "+Str(_nFatorFret,22,7)+If(_lDividir,"/","*")+CRLF
	_cValores+="_nFrete: "+Str(_nFrete,22,7)+CRLF
EndIf	

_cTeste+=_cValores+CRLF

//CHEP'S
_cqueryChep := " SELECT SUM(E2_VALOR) VLRCHEP FROM "+ retsqlname("SE2") "
_cqueryChep += " WHERE D_E_L_E_T_ = ' ' "
_cqueryChep += " AND E2_FILIAL = '" + xFilial("SE2") + "'"
_cqueryChep += " AND E2_NOMFOR LIKE '%CHEP%' "
_cqueryChep += " AND E2_BAIXA <> ' ' "
_cqueryChep += " AND E2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"

_cTeste+="CHEP'S: "+CHR(13)+CHR(10)
_cTeste+=_cqueryChep+CHR(13)+CHR(10)
_cValores:=""

MPSysOpenQuery( _cqueryChep ,"SE2T" ) 

If .not. SE2T->( Eof() )
	//1-FRETE SOMADO,2-FRETE,3-SEGURO,4-CHEP
	_aFret[1,4]+=(SE2T->VLRCHEP * (_nVlrGrupo/_nVlrGeral))
	_aFret[1,1]+=(SE2T->VLRCHEP * (_nVlrGrupo/_nVlrGeral))
	_cValores:="SE2T->VLRCHEP: "+Str(SE2T->VLRCHEP,22,7)+CRLF
EndIf

_cTeste+=_cValores+CRLF

If _nExp > 0
	//OCORRENCIAS DE FRETE
	_cqueryOcor := " SELECT SUM(ZF5_CUSTO+ZF5_CUSTOI+ZF5_CUSTOR) AS VLROCO FROM "+ RETSQLNAME("ZF5") "
	_cqueryOcor += " WHERE D_E_L_E_T_ = ' ' "
	_cqueryOcor += " AND ZF5_FILIAL = '" + xFilial("ZF5") + "'"
	_cqueryOcor += " AND ZF5_DTINI BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cqueryOcor += " AND ZF5_DTFIN BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"

	_cTeste+="OCORRENCIAS DE FRETE: "+CHR(13)+CHR(10)
	_cTeste+=_cqueryOcor+CHR(13)+CHR(10)
	_cValores:=""
	
	MPSysOpenQuery( _cqueryOcor ,"ZF5T" )
	
	If .not. ZF5T->( Eof() )
		//1-FRETE SOMADO,2-FRETE,3-SEGURO,4-CHEP,5-OCORRENCIAS
		_aFret[1,5]+=(ZF5T->VLROCO * (_nVlrGrupo/_nVlrGeral))
		_aFret[1,1]+=(ZF5T->VLROCO * (_nVlrGrupo/_nVlrGeral))
        _cValores:="ZF5T->VLROCO: "+Str(ZF5T->VLROCO,22,7)+CRLF
	EndIf

    _cTeste+=_cValores+CRLF
	
	ZF5T->( DBCloseArea() )
EndIf

SD2T->( DBCloseArea() )
SE2T->( DBCloseArea() )

nHandle := FCreate(_cdir+"QUERYS_MEST009FRT_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cTeste)
FClose(nHandle)
	
Return _aFret

/*
===============================================================================================================================
Programa----------: MEST009GRD
Autor-------------: Josué Danich Prestes
Data da Criacao---: 20/05/2016
Descricao---------: Grava detalhes do produto na ZE0
Parametros--------: 	_aze0 - dados da gravação
					  	_nI - posição de gravação
					  	_nvalor - valor do evento
					  	_nqtde - quantidade do evento
					  	_ccod1 - código do evento
					  	_ccod2 - código do subevento
					  	_desc - descrição do evento
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST009GRD(_aze0, _nI, _nvalor,_nqtde, _ccod1, _ccod2, _cdesc)
					
Local _cFiltro := ""

_cFiltro :=  xFilial("ZE0") + SubStr(DToS(MV_PAR05),5,2) +  SubStr(DToS(MV_PAR05),1,4) + _aze0[_nI][8] + _aze0[_nI][2]
_cFiltro +=  _ccod1 + _ccod2
	
If ZE0->( DBSeek( _cFiltro ) )
	//achou registro cria faz atualização
 	RecLock("ZE0",.F.)    
	ZE0->ZE0_QTDE	:= 	_nqtde
	ZE0->ZE0_VALOR	:= 	_nvalor
	ZE0->ZE0_VLRLT	:=  _nvalor / _ntotlei
	ZE0->ZE0_VDOLAR :=  _nvalor / (_ntotlei * _nTotdol)
 	("ZE0")->(MSUnLock())
Else
	//não achou registro cria um novo
 	RecLock("ZE0",.T.)    
	ZE0->ZE0_FILIAL := 	_aze0[_nI][1]	
	ZE0->ZE0_TPCUS	:=	_aze0[_nI][2]
	ZE0->ZE0_DTPCT	:=	_aze0[_nI][3]
	ZE0->ZE0_EVCUS	:=	_ccod1
	ZE0->ZE0_DEVCT	:=	_cdesc
	ZE0->ZE0_SEVCT	:= 	_ccod2
	ZE0->ZE0_DSECT	:= 	_cdesc
	ZE0->ZE0_GRPCT	:= 	_aze0[_nI][8]
	ZE0->ZE0_DGRPCT	:= 	_aze0[_nI][9]
	ZE0->ZE0_QTDE	:= 	_nqtde
	ZE0->ZE0_VALOR	:= 	_nvalor
	ZE0->ZE0_DATARQ	:= 	_aze0[_nI][12]
	ZE0->ZE0_VLRLT	:=  _nvalor / _ntotlei
	ZE0->ZE0_VDOLAR :=  _nvalor / (_ntotlei * _nTotdol)
 	("ZE0")->(MSUnLock())
EndIf

Return

/*
===============================================================================================================================
Programa----------: MEST009PMMTFQF
Autor-------------: Alex Walaluer
Data da Criacao---: 11/10/2016
Descricao---------: procura preço mínimo, preço máximo, total de faturamento e quantidade faturada
Parametros--------: _cCodProd: Código de um ou de uma lista de produtos separados por ;
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MEST009PMMTFQF(_cCodProd)

Local _nPrcmin := 0
Local _nPrcmax := 0
Local _nfatura := 0
Local _nqtdfat := 0
Local _cAlias  := GetNextAlias()
Local _cQuery  := " SELECT " 
	
_cQuery  	+= " D2_COD, "
_cQuery  	+= " Round(MAX( ( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) / D2_QUANT ),2) AS PRCMAX, "
_cQuery  	+= " Round(MIN( ( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) / D2_QUANT ),2) AS PRCMIN, "
_cQuery  	+= " SUM( D2_QUANT ) AS QTDE, "
_cQuery  	+= " SUM( D2_VALBRUT - ( D2_I_FRET + D2_VALICM + D2_VALIMP5 + D2_VALIMP6 + D2_VALIPI ) ) AS FATUR "
_cQuery  	+= " FROM " + RetSqlName("SD2") + " SD2 JOIN  " + RetSqlName("SF4") + " SF4 ON  SF4.F4_FILIAL = SD2.D2_FILIAL AND SF4.F4_CODIGO = SD2.D2_TES"

If MV_PAR07 <> 2
	If Empty(ZL6T->ZL6_FILIS)
		_cQuery  	+= " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
	Else
		_cQuery += " WHERE SD2.D2_FILIAL IN " +  FormatIn(AllTrim(ZL6T->ZL6_FILIS),";")
	EndIf	
Else
	_cQuery  	+= " WHERE SD2.D2_FILIAL = '" + xFilial("SD2") + "'"	
EndIf	

_cQuery   	+= " AND SD2.D2_EMISSAO >= '" + DToS(MV_PAR05) + "' AND D2_EMISSAO <= '" + DToS(MV_PAR06) + "' "
_cQuery   	+= " AND SD2.D2_QUANT > 0 "
_cQuery  	+= " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cCodProd),";")
_cQuery  	+= " AND SF4.D_E_L_E_T_ = ' ' "
_cQuery  	+= " AND SF4.F4_FILIAL = '" + xFilial("SF4") + "' "
_cQuery 	+= " AND SF4.F4_DUPLIC = 'S'	"
_cQuery 	+= " AND SF4.F4_ESTOQUE= 'S'	"
_cQuery 	+= " GROUP BY D2_COD "

MPSysOpenQuery( _cQuery , _cAlias ) 

If .not. (_cAlias)->( Eof() )
	_nPrcmin := (_cAlias)->PRCMIN
	_nPrcmax := (_cAlias)->PRCMAX
	_nfatura := (_cAlias)->FATUR
	_nqtdfat := (_cAlias)->QTDE
EndIf
		
(_cAlias)->( DBCloseArea() )

DBSelectArea("SD2")

Return {_nPrcmin,_nPrcmax,_nfatura,_nqtdfat}

/*
===============================================================================================================================
Programa----------: MEST9Calc2UN(_nQtde,_cProd)
Autor-------------: Alex Walaluer
Data da Criacao---: 11/10/2016
Descricao---------: devolve a segunda unidade
Parametros--------: _cSegUni: Se usa a segunda unidade
                    _nQtde: Quantidade na primeira unidade
                    _cProd: Código de um ou de uma lista de produtos separados por
Retorno-----------: Quantidade na segunda unidade
===============================================================================================================================
*/
Static Function MEST9Calc2UN(_cSegUni,_nQtde,_cProd)

Local _nPos:=0

_cProd:=AllTrim(_cProd)
_nPos:=AT(";",_cProd)

If _nPos > 1
   _cProd:=SubStr(_cProd,1,_nPos-1)
EndIf

SB1->(DBSetOrder(1))
SB1->(DBSeek(xFilial("SB1")+_cProd)) 

If _cSegUni = "S" .And. _nQtde # 0
	If  SB1->B1_CONV > 0
		If SB1->B1_TIPCONV = 'D'
			_nQtde:=(_nQtde/SB1->B1_CONV)
		Else
			_nQtde:=(_nQtde*SB1->B1_CONV)
		EndIf
	EndIf
EndIf

Return _nQtde

/*
===============================================================================================================================
Programa----------: MEST9BuscaZE0()
Autor-------------: Alex Walaluer
Data da Criacao---: 29/06/2017
Descricao---------: Devolve o valor de outras filiais
Parametros--------: _cFils: Filiais
Retorno-----------: Valor
===============================================================================================================================
*/
Static Function MEST9BuscaZE0(_cFilis,_cClientes,_cProds,_cCusto)

Local _cQuery := ""
Local _nFator := 0
Local _nValor := 0
Local _nQtde  := 0
Local _cMes   := MONTH(MV_PAR05)

_cQuery += " SELECT  SUM(ZE0_QTDE) QTDE,  SUM(ZE0_VALOR) TOTAL FROM "+ RETSQLNAME("ZE0")+" ZE0"
_cQuery += " WHERE ZE0.D_E_L_E_T_ = ' ' "
If !Empty(_cFilis)
    _cQuery += " AND ZE0_FILIAL IN "+FormatIn(AllTrim(_cFilis),";") 
EndIf    
If AllTrim(_cCusto) <> '000005' .And. AllTrim(ZL6T->ZL6_TPCUS) == '000002' .And. 'ESTOQUE INICIAL' $ Upper(ZL6T->ZL6_DESEVE)
	_cQuery += " AND ZE0_TPCUS = '000002' AND ZE0_DEVCT LIKE '%ESTOQUE FINAL%' "
	_cQuery += " AND ZE0_GRPCT = '"+ZL6T->ZL6_GRPCUS+"' "
	If _cMes = 1//Janeiro
		_cMes:="12"+Str( YEAR(MV_PAR05) - 1 , 4)
	Else
		_cMes:=StrZero(_cMes - 1 ,2) + AllTrim(Str(YEAR(MV_PAR05)))
	EndIf
	_cQuery += " AND ZE0_DATARQ = '"+_cMes+"' "
Else
	_cQuery += " AND ZE0_TPCUS = '000001' "
	_cQuery += " AND ZE0_DATARQ = '"+ StrZero(MONTH(MV_PAR05),2) + AllTrim(Str(YEAR(MV_PAR05))) +"' "
EndIf

If AllTrim(_cCusto) <> '000005' 
	MPSysOpenQuery( _cQuery, "ZE0T" ) 

	If .NOT. ZE0T->( Eof() )
		_nValor:=ZE0T->TOTAL
		_nQtde :=ZE0T->QTDE
	EndIf

	ZE0T->( DBCloseArea() )

	If AllTrim(ZL6T->ZL6_TPCUS) == '000002' .And. 'ESTOQUE INICIAL DE PRODUTO' $ Upper(ZL6T->ZL6_DESEVE)
		Return {_nQtde,_nValor}
	EndIf   
EndIf

_cQuery := ""
_cQuery += " SELECT B.FIL, B.QTDE, Round(RATIO_TO_REPORT(B.QTDE) OVER(),2) AS PRORP FROM "
_cQuery += "  (SELECT ZZM_CODIGO FIL, D2_CLIENTE, D2_LOJA, SUM(D2_QUANT) QTDE FROM "+ RETSQLNAME("SD2")+" D2 "
_cQuery += "         JOIN "+ RETSQLNAME("SA1")+" A1 ON D2_CLIENTE = A1_COD AND D2_LOJA = A1_LOJA "
_cQuery += "         JOIN "+ RETSQLNAME("ZZM")+" ZZM ON A1_CGC = ZZM_CGC "
_cQuery += "         WHERE D2.D_E_L_E_T_ = ' ' AND A1.D_E_L_E_T_ = ' ' AND ZZM.D_E_L_E_T_ = ' ' "
_cQuery += "         AND D2_FILIAL  IN "+FormatIn(AllTrim(_cFilis),";") 
_cQuery += "         AND D2_CLIENTE||D2_LOJA IN "+FormatIn(AllTrim(_cClientes),";")
_cQuery += "         AND D2_COD IN "+FormatIn(AllTrim(_cProds),";")
_cQuery += "         AND D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += "         GROUP BY ZZM_CODIGO, D2_CLIENTE, D2_LOJA) B "

MPSysOpenQuery( _cQuery, "SD2T" ) 

If .NOT. SD2T->( Eof() )
	If SD2T->FIL = cFilAnt
		_nFator:=SD2T->PRORP
	EndIf
	SD2T->( DBSkip() )
	If SD2T->FIL = cFilAnt
		_nFator:=SD2T->PRORP
	EndIf
EndIf

 SD2T->( DBCloseArea() )
_nValor:=_nValor*_nFator

If AllTrim(_cCusto) = '000005' 
	Return _nFator
Else
	Return {_nQtde,_nValor}
EndIf

/*
===============================================================================================================================
Programa----------: MEST9EstoqueFinal()
Autor-------------: Alex Walaluer
Data da Criacao---: 04/07/2018
Descricao---------: PARA O DEMONSTRATIVO DO ESTOQUE FINAL PLANILHA 03
Parametros--------: _oself
Retorno-----------: {Valor,Quantidade]
===============================================================================================================================
*/
Static Function MEST9EstoqueFinal(_oself,_lEnd)

Local _cQuery2  := ""
Local cAliasSB2 := GetNextAlias()
Local _dFim		:= MV_PAR06
Local _nQtde    := 0
Local _nQtdeItem:= 0
Local _nValrUni := 0
Local _nValor   := 0
Local _cSegUni  := ZL6T->ZL6_TUNID 
Local _cCodsProd:= ZL6T->ZL6_CODPRO
Local _cFiliais := ZL6T->ZL6_FILIS
Local _cFilAtual:= cFilant
Local aSaldo    := {}
Local _aProdutos:= {}
Local _cCampo   := "" , _cTotReg
Local _cFilSB1  := xFilial("SB1")
Local _dDtSB9   := LastDate(MV_PAR06)
Local _dULMES 	:= GETMV("MV_ULMES")      
Default _lEnd   := .F.

_cCampo += "(SELECT B1_TIPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "' "
_cCampo += "                                                     AND D_E_L_E_T_ = ' ' "
_cCampo += "                                                     AND SB1.B1_COD = SB2.B2_COD ) TIPO "
_dFim:= LastDate(_dFim)

_cQuery2:= " SELECT B2_COD,  B2_LOCAL,  B2_FILIAL, "+_cCampo+"  FROM " + RetSqlName("SB2") + " SB2 WHERE "

If AllTrim(ZL6T->ZL6_TPCUS) <> "000006"  // Aqui entra para a as Panilhas 01 e 02 (_lGera2Pla .Or. _lGera1Pla) 02-CUSTO E ESTOQUE MP (000004,000005) PLANILHAS 01 E 02
	If !Empty(_cFiliais)
		_cQuery2 += " SB2.B2_FILIAL IN "+FormatIn(AllTrim(_cFiliais ),";")+" AND "
	Else
		_cQuery2 += " SB2.B2_FILIAL = '"+cFilant+"' AND "
	EndIf   
	If !Empty(_cCodsProd)
		_cQuery2 += " SB2.B2_COD    IN "+FormatIn(AllTrim(_cCodsProd),";")+" AND "  // ElseReturn {0,0,,,,,0}
	EndIf   
Else//AllTrim(ZL6T->ZL6_TPCUS) == '000006' aqui entra só para a planilha 03 (_lGera3Pla) 03-ESTOQUE FINAL (000006).  
	_cQuery2 += " B2_FILIAL = '" +xFilial("SB2") + "' "
	_cQuery2 += " AND NOT EXISTS (SELECT B1_TIPO FROM " + RetSqlName("SB1") + " SB1 "
	_cQuery2 += "                                                        WHERE B1_FILIAL  = '" +xFilial("SB1") + "' "
	_cQuery2 += "                                                          AND D_E_L_E_T_ = ' ' "
	_cQuery2 += "                                                          AND SB1.B1_COD = SB2.B2_COD   "
	_cQuery2 += "                                                          AND (B1_TIPO IN ('PA','MP','PP','PI','SV') OR B1_MSBLQL = '1'  ) ) " 
	_cQuery2 += " AND ( "

	_cQuery2 += "      (SELECT B1_TIPO FROM " + RetSqlName("SB1") + " SB1 WHERE B1_FILIAL = '" +xFilial("SB1") + "' "
	_cQuery2 += "                                                          AND D_E_L_E_T_ = ' ' "
	_cQuery2 += "                                                          AND SB1.B1_COD = SB2.B2_COD ) "
	_cQuery2 += "      IN ('EM','IN')" 
	_cQuery2 += " OR "
	_cQuery2 += "      SubStr(B2_COD,1,4) IN (SELECT BM_GRUPO FROM " + RetSqlName("SBM") + " SBM "
	_cQuery2 += "   	                            WHERE BM_FILIAL = '" +xFilial("SBM") + "' AND D_E_L_E_T_ = ' ' AND "
	_cQuery2 += "                                         BM_GRUPO NOT IN ('0599','0800','0801','0814') AND  "
	_cQuery2 += "                                         SubStr(BM_GRUPO,1,2) <> '03' ) "

	_cQuery2 += "  ) AND  "
EndIf

_cQuery2 	+= " D_E_L_E_T_ = ' ' "
_cQuery2 	+= " ORDER BY B2_COD , B2_LOCAL "
  
If ValType(_oSelf) = "O"
	_oSelf:SetRegua1( 0 )
	_oSelf:SetRegua2( 3 )
	_oSelf:IncRegua1("Lendo Estoque dos itens...")
	_oSelf:IncRegua2("Lendo Estoque dos itens...")
	_nRegSB2:=0
EndIf
  
MPSysOpenQuery( _cQuery2 ,  cAliasSB2 ) 
DBSelectArea(cAliasSB2)
  
If ValType(_oSelf) = "O"
	COUNT To _nRegSB2
	_oSelf:SetRegua2( (_nRegSB2/100)+100 )
	_cTotReg:=AllTrim(Str(_nRegSB2))
	_nConta:=0
	_oSelf:IncRegua2("Lendo Item / Grupo: "+AllTrim(Str(_nConta,6))+" de "+_cTotReg+" [ " + AllTrim((cAliasSB2)->B2_COD) +" ] ")
	ProcessMessages()
EndIf

SB1->(DBSetOrder(1))
SB9->(DBSetOrder(1))
aSaldo:={0,0,,,,,0}
(cAliasSB2)->(DBGoTop())
While (cAliasSB2)->(!Eof())
	_nConta++
	If ValType(_oSelf) = "O" .And. (Mod(_nConta,100) = 0 .Or. _nConta < 100)
		_oSelf:IncRegua2("Lendo Item / Grupo: "+AllTrim(Str(_nConta,6))+" de "+_cTotReg+" [ " + AllTrim((cAliasSB2)->B2_COD) +" ] ")
		ProcessMessages()
		If _lEnd 
			If (_lEnd:=U_ITMsg("Confirma Cancelamento???? .","Atenção",,3,2,2))
				_lLoop:=.T.
				Return {0,0,{}}
			EndIf   
		EndIf
	EndIf

	cFilant:=(cAliasSB2)->B2_FILIAL
	If SB9->(DBSeek(cFilant+(cAliasSB2)->B2_COD+(cAliasSB2)->B2_LOCAL+DToS(_dDtSB9)))
		aSaldo:={SB9->B9_QINI,SB9->B9_VINI1,,,,,SB9->B9_QISEGUM}
		_cCalcEst:=""
	ElseIf (_dULMES < _dDtSB9)
		aSaldo := CalcEst( (cAliasSB2)->B2_COD,(cAliasSB2)->B2_LOCAL,_dFim+1,(cAliasSB2)->B2_FILIAL )
		_cCalcEst:="[CE]"
	EndIf   
	
	If ValType(aSaldo[1]) = "N" .And. aSaldo[1] <> 0//Se tiver quantidade
		If _cSegUni = "S"
			_nQtde    += aSaldo[7]
			_nQtdeItem:= aSaldo[7]
		Else
			_nQtde    += aSaldo[1]
			_nQtdeItem:= aSaldo[1]
		EndIf
		
		If _lGera3Pla
			_nValor += aSaldo[2]//Soma dos totais
			
			SB1->(DBSeek(_cFilSB1+(cAliasSB2)->B2_COD))
			If (cAliasSB2)->TIPO = 'EM'
				_cOrdem:="A "+AllTrim(SB1->B1_DESC)
			ElseIf (cAliasSB2)->TIPO = 'IN'
				_cOrdem:="B "+AllTrim(SB1->B1_DESC)
			Else
				_cOrdem:="C "+(cAliasSB2)->(SubStr(B2_COD,1,4))+" "+AllTrim(SB1->B1_DESC)+(cAliasSB2)->B2_COD//(cAliasSB2)->B2_LOCAL+" "+(cAliasSB2)->TIPO+" "+(cAliasSB2)->B2_COD
			EndIf   

	        aAdd(_aProdutos,{(cAliasSB2)->B2_COD,;//01
	                     aSaldo[2]              ,;//02
	                     _nQtdeItem             ,;//03
	                     (cAliasSB2)->B2_LOCAL  ,;//04
	                     (cAliasSB2)->TIPO      ,;//05
	                     (cAliasSB2)->(SubStr(B2_COD,1,4)),;//06 - Grupo
	                     _cOrdem                          ,;//07 - ORDENACAO
	                     _cCalcEst                        })//08 - CALCEST  
        EndIf
	EndIf   
	(cAliasSB2)->(DBSkip())
EndDo

cFilant:=_cFilAtual
//                 Ordenação// 7-ORDEM (ABC) + 6-GRUPO + 4-Local + 5-TIPO + 1-CODIGO DO ITEM
_aProdutos:= aSort(_aProdutos,,,{|x,y| x[7] < y[7] })
_nValrUni:=(_nValor/_nQtde)//Valor Unitario

(cAliasSB2)->( DBCloseArea() )

If ValType(_oSelf) = "O"
	_oSelf:IncRegua2("OK")
	ProcessMessages()
EndIf

Return {_nValrUni,_nQtde,_aProdutos}

/*
===============================================================================================================================
Programa----------: MEST9BuscaSB2()
Autor-------------: Andre Lisboa
Data da Criacao---: 21/07/2017
Descricao---------: Retorna saldo atual conforme data final informada no parametro do relatorio
Parametros--------: _cproduto: Produtos
Retorno-----------: Quantidade
===============================================================================================================================
*/
Static Function MEST9BscSB2(_cproduto,_lPorItem)

Local _dFim		:= MV_PAR06
Local _aSaldos	:= {}
Local _cLocal	:= "03;20;21;22;30;31;32;33;34;40;04;07;50;52"
Local _aItem	:= {}
Local _aLocal	:= {}
Local _nSldAtu	:= 0
Local _nValor	:= 0
Local _aFilial	:= {}
Local _atrab	:= {}
Local _aTotItem := {}
Local _nSldItem := 0 , _ji , _ii  , _xi  , _zi
Local _cFilGuard:= cFilant

Default _lPorItem := .F.
_aItem 	:= StrTokArr(AllTrim(_cproduto), ';')
_aLocal	:= StrTokArr(AllTrim(_cLocal), ';')
_aFilial:= StrTokArr(AllTrim(_cfilis), ';')

For _xi := 1 To Len(_aItem)   
	For _ii:= 1 To Len(_aLocal)
		If !Empty(_cfilis)
			For _ji := 1 To Len(_aFilial)
				aAdd(_atrab,{_aitem[_xi],_alocal[_ii], _aFilial[_ji]})
			Next		
		Else	
			aAdd(_atrab,{_aitem[_xi],_alocal[_ii]})
		EndIf
	Next	
Next
For _zi := 1 To Len(_atrab)
   If !Empty(_cfilis)
        cFilant:=_atrab[_zi,3]
		_aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1, _atrab[_zi,3] ) //obtém o saldo final em estoque na data informada
	Else
		_aSaldos := CalcEst( _atrab[_zi,1] , _atrab[_zi,2] , _dFim + 1 ) //obtém o saldo final em estoque na data informada			
	EndIf	
	If _cSegUni = "S"
        _nSldItem:= _asaldos[7]
	Else
        _nSldItem:= _asaldos[1]
	EndIf
	_nSldAtu += _nSldItem
	_nValor  += _asaldos[2]

	If (_nPos:=aScan(_aTotItem,{|I| I[1] == _atrab[_zi,1] } )) = 0
	   aAdd(_aTotItem,{_atrab[_zi,1],_nSldItem,_asaldos[2]})
	Else
	   _aTotItem[_nPos,2]+=_nSldItem
	   _aTotItem[_nPos,3]+=_asaldos[2]
	EndIf
Next	

cFilant:=_cFilGuard

If _lPorItem
   Return _aTotItem
Else
   Return _nSldAtu
EndIf

/*
===============================================================================================================================
Programa----------: MEST92Plan()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/06/2018
Descricao---------: Retorna o LayOut da Planilha 2 "02-Custo / Estoque - MP          "
Parametros--------: _azeNew
Retorno-----------: _axml 
===============================================================================================================================
*/
Static Function MEST92Plan(_aZeNew)
Local _AXML   := {}

//Definições
_AXML:=MEST9CabNovo(_AXML)

//CUSTO MP PASTA 1
_AXML:=  MEST9PCustoMP(_AXML,_aZeNew)//Rodas os codigos "000005"

//ESTOQUE MP PASTA
_AXML:=MEST9PEstoqueMP(_AXML,_aZeNew)//Rodas os codigos "000004" 

Return _AXML

/*
===============================================================================================================================
Programa----------: MEST93Plan()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/07/2018
Descricao---------: Retorna o LayOut da Planilha 3  "03-Demonstrativo do Estoque Final"
Parametros--------: _azeNew
Retorno-----------: _axml 
===============================================================================================================================
*/
Static Function MEST93Plan(_aZeNew)

Local _AXML      := {}
Local _aProdutos := {}
Local _aTotais   := {0,0} , _nI , P
Local _cArq01    := "\data\italac\mest009\MEST009_PLAN_03.txt"

//Definições
If FT_FUSE(_cArq01) == -1
	U_ITMsg("Não foi possível abrir o arquivo: "+_cArq01 , "Arquivo inválido" , "Favor verificar se o arquivo existe.",1)
	Return _AXML
EndIf

FT_FGOTOP()//PONTO NO TOPO

If FT_FLASTREC() == 0
	U_ITMsg("O arquivo "+_cArq01+" não possui dados.","Arquivo inválido","Favor verificar se o arquivo esta vazio.",1)
	Return _AXML
EndIf

While !FT_FEof()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	_cLinha:=FT_FREADLN()
	If !Empty(_cLinha)
		aAdd(_AXML,AllTrim(_cLinha))
	EndIf
	FT_FSKIP()   //próximo registro no arquivo txt
EndDo

FT_FUSE()//Fecha o arquivo

SB1->(DBSetOrder(1))
For _nI := 1 To Len(_azeNew)//Rodas os codigos '000006' 
  	If _azeNew[_nI][02] <> '000006'//AllTrim(ZL6T->ZL6_TPCUS)
  	   Loop
  	EndIf

	If _azeNew[_nI][08] = '000001' // PRODUTOS
		_aItens:=_azeNew[_nI][23]//_aProdutos DA FUNCAO  MEST9EstoqueFinal()
		_cGrupoIni:=""
		_nQtdGrupo:=0
		_nTotGrupo:=0
		
		For P := 1 To Len(_aItens)
			If Empty(_cGrupoIni) .And. !_aItens[P][5] $ 'EM,IN'
				_cGrupoIni:=_aItens[P][6]
				aAdd(_aProdutos,{"","",0,0,0,0})//PULA LINHA
			EndIf  

			If !_aItens[P][5] $ 'EM,IN'
				If _cGrupoIni <> _aItens[P][6]
				If MV_PAR08 = 2 //Analitico
					_cDescri:="TOTAL Grupo "+_cGrupoIni+" - "+Posicione("SBM",1,xFilial("SBM")+_cGrupoIni,"BM_DESC")+_aItens[P][8]
				Else
					_cDescri:=_cGrupoIni+" - "+Posicione("SBM",1,xFilial("SBM")+_cGrupoIni,"BM_DESC")+_aItens[P][8]
				EndIf
				_cInidade:="DIV"//Especie ,Descricao, Valor Unitario        ,Quantidade,Valor Total
				aAdd(_aProdutos,{_cInidade,_cDescri ,(_nTotGrupo/_nQtdGrupo),_nQtdGrupo,_nTotGrupo,'' })
				If MV_PAR08 = 2 //Analitico
					aAdd(_aProdutos,{"","",0,0,0,0})//PULA LINHA
				EndIf   
				//Reinicia
				_cGrupoIni:=_aItens[P][6]
				_nQtdGrupo:=0
				_nTotGrupo:=0

				EndIf
				_nQtdGrupo+=_aItens[P][3]//Quantidade do Grupo
				_nTotGrupo+=_aItens[P][2]//Valor do Grupo
			EndIf
			
			If MV_PAR08 = 2 .Or. _aItens[P][5] $ 'EM,IN'   //Analitico OU tipos 'EM','IN'
				SB1->(DBSeek(xFilial("SB1")+_aItens[P][1])) 
				If  _aItens[P][5] $ 'EM,IN'
					_cDescri:="["+AllTrim(_aItens[P][1])+"-"+_aItens[P][4]+"-"+SB1->B1_TIPO+"]-"+SB1->B1_DESC+_aItens[P][8]
				Else
					_cDescri:="Item Grupo "+RTRIM(SB1->B1_GRUPO)+"-["+AllTrim(_aItens[P][1])+"-"+_aItens[P][4]+"-"+SB1->B1_TIPO+"]-"+SB1->B1_DESC+_aItens[P][8]
				EndIf    
				If _azeNew[_nI][17] = "S"
					_cInidade:=SB1->B1_SEGUM
				Else
					_cInidade:=SB1->B1_UM
				EndIf           // Especie,Descricao, Valor Unitario              ,Quantidade   ,Valor Total
				aAdd(_aProdutos,{_cInidade,_cDescri ,(_aItens[P][2]/_aItens[P][3]),_aItens[P][3],_aItens[P][2],_aItens[P][7]})//DADOS DO PRODUTO
			EndIf              //    01      02                03                      04            05          06  

			_aTotais[1]+=_aItens[P][3]//Quantidade Total
			_aTotais[2]+=_aItens[P][2]//Valor Total

			If P = Len(_aItens)//ULTIMO TOTAL
				If MV_PAR08 = 2 //Analitico
					_cDescri:="TOTAL Grupo "+_cGrupoIni+" - "+Posicione("SBM",1,xFilial("SBM")+_cGrupoIni,"BM_DESC")+_aItens[P][8]
				Else
					_cDescri:=_cGrupoIni+" - "+Posicione("SBM",1,xFilial("SBM")+_cGrupoIni,"BM_DESC")+_aItens[P][8]
				EndIf
				_cInidade:="DIV"//Especie,Descricao, Valor Unitario        ,Quantidade,Valor Total
				aAdd(_aProdutos,{_cInidade,_cDescri ,(_nTotGrupo/_nQtdGrupo),_nQtdGrupo,_nTotGrupo ,'' })//DADOS DO GRUPO
			EndIf
		Next
	EndIf
Next

aAdd( _AXML,' <Worksheet ss:Name="ESTOQUE FINAL">')
aAdd( _AXML,'  <Table ss:ExpandedColumnCount="999999" ss:ExpandedRowCount="999999" x:FullColumns="1"')
aAdd( _AXML,'   x:FullRows="1" ss:DefaultRowHeight="15">')
aAdd( _AXML,'   <Column ss:Index="2" ss:AutoFitWidth="0" ss:Width="288"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="85.5"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="111.75"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="166.5"/> ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s64"><Data ss:Type="String">        DEMONSTRATIVO DO ESTOQUE FINAL - UND. ' + FWFilialName( cEmpAnt , xFilial("ZL6") , 2 )  + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s66"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s64"><Data ss:Type="String">Ultimo dia do Mes</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s64"><Data ss:Type="String">' + MESEXTENSO(MONTH(MV_PAR05)) + '/' + AllTrim(Str(YEAR(MV_PAR05))) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s68"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s70"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">Especie</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">Discriminacao</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s72"><Data ss:Type="String">Valor Unitario</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">Quantidade</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">Valor Total</Data></Cell>')
aAdd( _AXML,'   </Row>')

For _nI := 1 To Len(_aProdutos)
    If Empty(_aProdutos[_nI,1])//Pula LINHA
       aAdd( _AXML,'<Row> ')
       aAdd( _AXML,'</Row>')
       Loop
    EndIf

    _aProdutos[_nI,2]:=StrTran(AllTrim(_aProdutos[_nI,2]),"<","")
    _aProdutos[_nI,2]:=StrTran(_aProdutos[_nI,2],">","")

    aAdd( _AXML,'    <Row> ')
    aAdd( _AXML,'    <Cell ss:StyleID="s73"><Data ss:Type="String">' + AllTrim(_aProdutos[_nI,1])  + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="String">' + AllTrim(_aProdutos[_nI,2])  + '</Data></Cell>')
    If "TOTAL " == LEFT(_aProdutos[_nI,2],6) .And. MV_PAR08 = 2 
       aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,3])) + '</Data></Cell>')
       aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,4])) + '</Data></Cell>')
       aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,5])) + '</Data></Cell>')
       aAdd( _AXML,'    </Row>')
    Else
       aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,3])) + '</Data></Cell>')
       aAdd( _AXML,'    <Cell ss:StyleID="s91"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,4])) + '</Data></Cell>')
       aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">' + AllTrim(Str( _aProdutos[_nI,5])) + '</Data></Cell>')
       aAdd( _AXML,'    </Row>')
    EndIf
Next
  
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="2" ss:StyleID="m766764296"><Data ss:Type="String">TOTAL GERAL</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">' + AllTrim(Str( _aTotais[1])) + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aTotais[2])) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'  </Table>')
aAdd( _AXML,'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">')
aAdd( _AXML,'   <PageSetup>')
aAdd( _AXML,'    <Header x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <Footer x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.511811024"')
aAdd( _AXML,'     x:Right="0.511811024" x:Top="0.78740157499999996"/>')
aAdd( _AXML,'   </PageSetup>')
aAdd( _AXML,'   <Unsynced/>')
aAdd( _AXML,'   <Selected/>')
aAdd( _AXML,'   <Panes>')
aAdd( _AXML,'    <Pane>')
aAdd( _AXML,'     <Number>3</Number>')
aAdd( _AXML,'     <RangeSelection>R1C1:R1C4</RangeSelection>')
aAdd( _AXML,'    </Pane>')
aAdd( _AXML,'   </Panes>')
aAdd( _AXML,'   <ProtectObjects>False</ProtectObjects>')
aAdd( _AXML,'   <ProtectScenarios>False</ProtectScenarios>')
aAdd( _AXML,'  </WorksheetOptions>')
aAdd( _AXML,' </Worksheet>')
aAdd( _AXML,'</Workbook>')

Return _AXML

/*
===============================================================================================================================
Programa----------: MEST9CabNovo()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/06/2018
Descricao---------: Monta cabecalho do excel
Parametros--------: _AXML
Retorno-----------: _AXML
===============================================================================================================================
*/
Static Function MEST9CabNovo(_AXML)

Local _cArq01:= "\data\italac\mest009\MEST009_PLAN_02.txt"
	
If FT_FUSE(_cArq01) == -1
	U_ITMsg("Não foi possível abrir o arquivo: "+_cArq01,"Arquivo inválido","Favor verificar se o arquivo se esta correto.",1)
	Return _AXML
EndIf

FT_FGOTOP()//PONTO NO TOPO

If FT_FLASTREC() == 0
	U_ITMsg("O arquivo "+_cArq01+" não possui dados.","Arquivo inválido","Favor verificar se o arquivo se esta correto.",1)
	Return _AXML
EndIf

While !FT_FEof()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	_cLinha:=FT_FREADLN()
	If !Empty(_cLinha)
		aAdd(_AXML,AllTrim(_cLinha))
	EndIf
	FT_FSKIP()   //próximo registro no arquivo txt
EndDo

FT_FUSE()//Fecha o arquivo

Return _AXML 

/*
===============================================================================================================================
Programa----------: MEST9PCustoMP()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/06/2018
Descricao---------: Monta Pasta Materia prima do excel
Parametros--------: _AXML,_aZeNew,lSoPegaVlrs,_oSelf
Retorno-----------: _AXML
===============================================================================================================================
*/
Static Function MEST9PCustoMP(_AXML,_aZeNew,lSoPegaVlrs,_oSelf)

Local _nI
Local _aCustOpera:={}
Local _aLeiteProp:={}
Local _aLeiteTerc:={}
Local _aResumoGer:={}
Local _aSoroLeite:={}
Local _aSoroConce:={}
Local _aSoroPreCo:={}
Local _aCremeLeit:={}
Default lSoPegaVlrs := .F.

_aCustoMP:={}//MEST9PCustoMP(,.T.)         2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2,7-Custo Materia Gorda
aAdd(_aCustoMP,{"LEITE IN NATURA"         ,0      ,0        ,0      ,0     ,0        ,0                    })//01
aAdd(_aCustoMP,{"SORO DE LEITE"           ,0      ,0        ,0      ,0                                     })//02
aAdd(_aCustoMP,{"SORO CONCENTRADO"        ,0      ,0        ,0      ,0                                     })//03    
aAdd(_aCustoMP,{"CREME DE LEITE TERCEIROS",0      ,0        ,0      ,0                                     })//04     
aAdd(_aCustoMP,{"DIFERENCA ESTOQUE MP"    ,0      ,0        ,0      ,0                                     })//05
aAdd(_aCustoMP,{"SORO PRE-CONCENTRADO"    ,0      ,0        ,0      ,0                                     })//06

If lSoPegaVlrs//SÓ PARA NÃO DAR ERRO
	aAdd(_aCusto04,{"CUSTO OPERACIONAL                 ",0,0,0})//01
	aAdd(_aCusto04,{"CUSTO OPERACIONAL FILIAIS         ",0,0,0})//02
	aAdd(_aCusto04,{"CUSTO LEITE IN-NATURA + FRETE     ",0,0,0})//03
	aAdd(_aCusto04,{"CUSTO SORO DE LEITE + FRETE       ",0,0,0})//04
	aAdd(_aCusto04,{"CUSTO SORO CONCENTRADO + FRETE    ",0,0,0})//05
	aAdd(_aCusto04,{"CUSTO CREME DE LEITE + FRETE      ",0,0,0})//06
	aAdd(_aCusto04,{"CUSTO SORO PRE-CONCENTRADO + FRETE",0,0,0})//07
EndIf

If ValType(_oSelf) = "O"
   _oRegua:=_oSelf
EndIf
If ValType(_oRegua) = "O"
   _oRegua:SetRegua2( 15 )
   _oRegua:IncRegua2("CMP-Lendo custo leite operacional ...")
	ProcessMessages()
EndIf
ZLT->(DBSeek(xFilial()+cFilant))
_cSetor   :=AllTrim(ZLT->ZLT_SETOR)
If RIGHT(_cSetor,1) = ";"
   _cSetor:=LEFT(_cSetor, Len(_cSetor)-1 )
EndIf

If (nPos  :=aScan(_aZeNew,{|Z| Z[2] == '000005'} ) ) <> 0
	_cFils :=AllTrim(_aZeNew[nPos,22])//ZL6T->ZL6_FILIS 
	_aSetor :=StrTokArr(_cSetor,';')
	_cSetor:=""
	For _nI := 1 To Len(_aSetor)
		If !LEFT(_aSetor[_nI],2) $ _cFils
			_cSetor+=_aSetor[_nI]+";"
		EndIf   
	Next              
	If RIGHT(_cSetor,1) = ";"
		_cSetor:=LEFT(_cSetor, Len(_cSetor)-1 )
	EndIf
EndIf
   
_nVolLeite:=VolLeite(_cSetor)
_nTotValor:=0
If (nPos:=aScan(_aCusto04,{|C| AllTrim(C[1]) == "CUSTO OPERACIONAL FILIAIS"} )) <> 0
	_nTotValor:=_aCusto04[nPos,3]
EndIf   

aAdd(_aCustOpera,{"CUSTO OPERACIONAL",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//01 - é regravado no CUSTO POSTO/FABRICA - LEITE PROPRIO

//LEITE PROPRIO
If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo leite proprio MIX ...")
	ProcessMessages()
EndIf
_nTotValor:=GetVlrMix(_cSetor)   

_nVlrSoma :=MEST9ICMS("FUNDOLEITE",,cFilant)// = FUNDOPEM
_nTotValor+=_nVlrSoma

_nIT_TXFUNDE:=SuperGetMV("IT_TXFUNDE",.F.,0)// = FUNDESA
_nVlrSoma :=(_nIT_TXFUNDE*_nVolLeite)
_nTotValor+=_nVlrSoma

aAdd(_aLeiteProp,{"CUSTO LEITE PROPRIO - MIX",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//01  - OK

aAdd(_aLeiteProp,{"CUSTO FRETE 1o. PERCURSO",0,0,0 })//02 PREENCHE ABAIXO

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aSetor:=StrTokArr(_cSetor,';')
_cFilis:=""
For _nI := 1 To Len(_aSetor)
    If !LEFT( _aSetor[_nI],2 ) $ _cFilis
       _cFilis+=LEFT( _aSetor[_nI],2 )+";"//Paga as filiais dos setores
    EndIf   
Next              
_cFilis   := LEFT(_cFilis,Len(_cFilis)-1)
_aTotias  := CusFret2P(_cFilis,"F;P","001")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aLeiteProp,{"CUSTO FRETE 2o. PERCURSO (SEM ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//03 - OK

//                                           2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"LEITE IN NATURA"         ,0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[1,4]:=_nTotValor//Valor do Frete do Leite IN NATURA

_aLeiteProp[2,2]:=( _aLeiteProp[1,2]-_nVolLeite )//"CUSTO FRETE 1o. PERCURSO" - só preenche a qtde

_nTotValor:=_nVolLeite:=0
If (nPos  :=aScan(_aZeNew,{|Z| Z[2] == '000005'} ) ) <> 0
	_cFils :=AllTrim(_aZeNew[nPos,22])//ZL6T->ZL6_FILIS 
	_aFils :=StrTokArr(_cFils,';')
	_cSetor:=""
	For _nI := 1 To Len(_aFils)
		If ZLT->(DBSeek(xFilial()+_aFils[_nI]))
			_cSetor+=AllTrim(ZLT->ZLT_SETOR)//Pega os setores das filiais
			If RIGHT(_cSetor,1) <> ";"
				_cSetor+=";"
			EndIf
		EndIf   
	Next              
	_cSetor:=LEFT(_cSetor, Len(_cSetor)-1 )
	_nVolLeite:=VolLeite(_cSetor) //VOLUME
	_nTotValor:=GetVlrMix(_cSetor)//VALOR

	//Percentual da Filial  //_cFilis,_cClientes      ,_cProds         ,_cCusto
	_nPerc:=MEST9BuscaZE0(_cFils ,_aZeNew[nPos,25],_aZeNew[nPos,15],'000005')

	_nVlrSoma :=MEST9ICMS("FUNDOLEITE",,_cFils)// = FUNDOPEM
	_nTotValor+=_nVlrSoma

	_nVolLeite:=_nVolLeite*_nPerc
	_nTotValor:=_nTotValor*_nPerc   
EndIf

_nIT_TXFUNDE:=SuperGetMV("IT_TXFUNDE",.F.,0)// = FUNDESA
_nVlrSoma :=(_nIT_TXFUNDE*_nVolLeite)
_nTotValor+=_nVlrSoma

aAdd(_aLeiteProp,{"CUSTO LEITE POSTOS - MIX",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//04  - OK

_nVolLeite:= _aLeiteProp[1,2]+_aLeiteProp[4,2] //+_aLeiteProp[2,2]+_aLeiteProp[3,2]
_nTotValor:= _aLeiteProp[1,3]+_aLeiteProp[2,3]+_aLeiteProp[3,3]+_aLeiteProp[4,3]
aAdd(_aLeiteProp,{"CUSTO POSTO/FABRICA - LEITE PROPRIO",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//05 - OK 

//REGRA CUSTO OPERACIONAL
_aCustOpera[1,2]:=_aLeiteProp[5,2]                    // VOLME DO CUSTO OPERACIONAL
_aCustOpera[1,4]:=_aCustOpera[1,3] / _aLeiteProp[5,2] // CUSTO / L DO CUSTO OPERACIONAL

//REGRA CUSTO OPERACIONAL
//LEITE TERCEIROS
If ValType(_oRegua) = "O"
	_oRegua:IncRegua2("CMP-Lendo custo leite terceiros c/ MG e ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusComICMS(_cFilis,"001")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aLeiteTerc,{"CUSTO LEITE TERCEIROS (COM MG E COM ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//01 - OK

If ValType(_oRegua) = "O"
	_oRegua:IncRegua2("CMP-Lendo custo excedente materia gorda ...")
	ProcessMessages()
EndIf
_aTMGICMS := CusMGCMS(_cFilis)
_nVolLeite:= _aTMGICMS[1,1]
_nTotValor:= _aTMGICMS[1,2]*(-1)
aAdd(_aLeiteTerc,{"CUSTO EXCEDENTE MATERIA GORDA  ( - )",0,_nTotValor,(_nTotValor/_nVolLeite) })//02 - OK

//                                           2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2,7-Custo Materia Gorda
//aAdd(_aCustoMP,{"LEITE IN NATURA"         ,0      ,0        ,0      ,0     ,0        ,0                    })//01
_aCustoMP[1,7]:=_aTMGICMS[1,2]//Valor do CUSTO EXCEDENTE MATERIA GORDA

_nVolLeite:= _aLeiteTerc[01,2]//Para dividir
_nTotValor:= _aTMGICMS[1,3]*(-1)//"001"
aAdd(_aLeiteTerc,{"APROVEITAMENTO CREDITO ICMS ( - ) (obs.: Desconsiderado transf. entre filiais)",0,_nTotValor,(_nTotValor/_nVolLeite) })//03 - OK

_nVolLeite:= _aLeiteTerc[01,2]//+_aLeiteTerc[2,2]+_aLeiteTerc[3,2]
_nTotValor:= _aLeiteTerc[01,3]+_aLeiteTerc[02,3]+_aLeiteTerc[03,3]
aAdd(_aLeiteTerc,{"CUSTO LEITE TERCEIROS (SEM MG E  SEM ICMS)",0,_nTotValor,(_nTotValor/_nVolLeite) })//04 - OK

_nVolLeite:= 0//Elker/Naum e Flavio analisarao o relatorio ->Naum definira data
_nTotValor:= 0//Elker/Naum e Flavio analisarao o relatorio ->Naum definira data
aAdd(_aLeiteTerc,{"LEITE DIRETO P/ FABRICA SEM CUSTO DE FRETE",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//05

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusFret2P(_cFilis,"T","001")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aLeiteTerc,{"CUSTO FRETE 2o. PERCURSO (SEM ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//06 - OK

//                                           2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"LEITE IN NATURA"         ,0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[1,6]:=_nTotValor//Valor do Frete do Leite TERCEIROS

If _aLeiteTerc[5,2] = 0
   _aLeiteTerc[5,2]:=_aLeiteTerc[1,2]-_nVolLeite//"LEITE DIRETO P/ FABRICA SEM CUSTO DE FRETE" POR ENQUANTO
EndIf   

_nVolLeite:=_aLeiteTerc[5,2]+_aLeiteTerc[6,2]
_nTotValor:=_aLeiteTerc[4,3]+_aLeiteTerc[5,3]+_aLeiteTerc[6,3]
aAdd(_aLeiteTerc,{"CUSTO EFETIVO LEITE TERCEIROS + FRETE (S / MG E S/ ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//07 - OK

//RESUMO GERAL - CUSTO LEITE
_nVolLeite:= _aLeiteProp[1,2]+_aLeiteProp[4,2]
_nTotValor:= _aLeiteProp[1,3]+_aLeiteProp[2,3]+_aLeiteProp[3,3]+_aLeiteProp[4,3]
aAdd(_aResumoGer,{"CUSTO LEITE - PROPRIO",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//01 - OK

_nVolLeite:= _aLeiteTerc[4,2]+_aLeiteTerc[5,2]+_aLeiteTerc[6,2]
_nTotValor:= _aLeiteTerc[4,3]+_aLeiteTerc[5,3]+_aLeiteTerc[6,3]
aAdd(_aResumoGer,{"CUSTO LEITE - TERCEIROS",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//02 - OK

_nVolLeite+= _aLeiteProp[1,2]+_aLeiteProp[4,2] //"CUSTO LEITE - TERCEIROS += CUSTO LEITE - PROPRIO
_nTotValor+= _aLeiteProp[1,3]+_aLeiteProp[2,3]+_aLeiteProp[3,3]+_aLeiteProp[4,3]//"CUSTO LEITE - TERCEIROS += CUSTO LEITE - PROPRIO
aAdd(_aResumoGer,{"CUSTO (FIFO) LEITE IN-NATURA - TOTAL",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite) })//03 - OK

_aCusto04[3,2]:=_nVolLeite
_aCusto04[3,3]:=_nTotValor
_aCusto04[3,4]:=(_nTotValor/_nVolLeite)

//                                           2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"LEITE IN NATURA"         ,0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[1,2]:=(_nTotValor/_nVolLeite)//"CUSTO MP LEITE IN-NATURA"
_aCustoMP[1,3]:=((_aCustoMP[1,4]+_aCustoMP[1,6])/_nVolLeite)//Custo dos Fretes por Qtde total dos leites
_aCustoMP[1,5]:=_nVolLeite//Qtde total dos leites

_nVolLeite:= _aLeiteTerc[2,2]
_nTotValor:= _aLeiteTerc[2,3]
aAdd(_aResumoGer,{"CUSTO EXC. MATERIA GORDA A TRANSPORTAR P/ CREME DE LEITE UHT",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//04 - OK

//SORO DE LEITE
If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo soro c/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusComICMS(_cFilis,"002")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aSoroLeite,{"CUSTO SORO C/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//01 - OK

_nTotValor:= _aTMGICMS[2,3]*(-1)//"002"
aAdd(_aSoroLeite,{"APROVEITAMENTO CREDITO ICMS ( - )"   ,0,_nTotValor,(_nTotValor/_nVolLeite)})//02 - OK

_nTotValor:= _aSoroLeite[1,3]+_aSoroLeite[2,3]
aAdd(_aSoroLeite,{"CUSTO SORO S/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//03 - OK

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusFret2P(_cFilis,"F;P;T","002")
_nTotValor:= _aTotias[2]
aAdd(_aSoroLeite,{"CUSTO FRETE 2o. PERCURSO (S/ ICMS)"  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//04 - OK
//                                2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"SORO DE LEITE",0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[2,3]:=(_nTotValor/_nVolLeite)//"SORO DE LEITE custo do frete"
_aCustoMP[2,4]:=_nTotValor//"SORO DE LEITE frete"
_aCustoMP[2,5]:=_nVolLeite//"SORO DE LEITE qtde"

_nVolLeite:= _aSoroLeite[1,2]
_nTotValor:= _aSoroLeite[3,3]+_aSoroLeite[4,3]
aAdd(_aSoroLeite,{"CUSTO (FIFO) EFETIVO - SORO DE LEITE",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//05  - OK

_aCustoMP[2,2]:=(_nTotValor/_nVolLeite)//"SORO DE LEITE"
_aCusto04[4,2]:=_nVolLeite
_aCusto04[4,3]:=_nTotValor
_aCusto04[4,4]:=(_nTotValor/_nVolLeite)

//SORO DE LEITE PRE-CONCENTRADO
If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo soro PRE-CONCENTRADO c/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusComICMS(_cFilis,"011")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aSoroPreCo,{"CUSTO SORO PRE-CONCENTRADO C/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//01

_nTotValor:= _aTMGICMS[3,3]*(-1)//"003"
aAdd(_aSoroPreCo,{"APROVEITAMENTO CREDITO ICMS ( - )"               ,0,_nTotValor,(_nTotValor/_nVolLeite)})//02 - OK

_nTotValor:= _aSoroPreCo[1,3]+_aSoroPreCo[2,3]
aAdd(_aSoroPreCo,{"CUSTO SORO PRE-CONCENTRADO S/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//03 - OK

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusFret2P(_cFilis,"F;P;T","011")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aSoroPreCo,{"CUSTO FRETE 2o. PERCURSO (S/ ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//04 - OK
//                                    2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"SORO PRE-CONCENTRADO"",0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[6,3]:=(_nTotValor/_nVolLeite)//"SORO PRE-CONCENTRADO" custo do frete"
_aCustoMP[6,4]:=_nTotValor//"SORO PRE-CONCENTRADO" frete"
_aCustoMP[6,5]:=_nVolLeite//"SORO PRE-CONCENTRADO" qtde"

_nVolLeite:= _aSoroPreCo[1,2]//+_aSoroPreCo[2,2]+_aSoroPreCo[3,2]+_aSoroPreCo[4,2]
_nTotValor:= _aSoroPreCo[3,3]+_aSoroPreCo[4,3]
aAdd(_aSoroPreCo,{"CUSTO (FIFO) EFETIVO - SORO DE LEITE CONCENTRADO",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//05 - OK
_aCustoMP[6,2]:=(_nTotValor/_nVolLeite)//"SORO CONCENTRADO"

_aCusto04[7,2]:=_nVolLeite
_aCusto04[7,3]:=_nTotValor
_aCusto04[7,4]:=(_nTotValor/_nVolLeite)

//SORO DE LEITE CONCENTRADO
If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo soro concentrado c/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusComICMS(_cFilis,"003")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aSoroConce,{"CUSTO SORO CONCENTRADO C/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//01

_nTotValor:= _aTMGICMS[3,3]*(-1)//"003"
aAdd(_aSoroConce,{"APROVEITAMENTO CREDITO ICMS ( - )"               ,0,_nTotValor,(_nTotValor/_nVolLeite)})//02 - OK

_nTotValor:= _aSoroConce[1,3]+_aSoroConce[2,3]
aAdd(_aSoroConce,{"CUSTO SORO CONCENTRADO S/ ICMS"                  ,_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//03 - OK

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusFret2P(_cFilis,"F;P;T","003")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aSoroConce,{"CUSTO FRETE 2o. PERCURSO (S/ ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//04 - OK
//                                    2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"SORO CONCENTRADO"",0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[3,3]:=(_nTotValor/_nVolLeite)//"SORO CONCENTRADO" custo do frete"
_aCustoMP[3,4]:=_nTotValor//"SORO CONCENTRADO" frete"
_aCustoMP[3,5]:=_nVolLeite//"SORO CONCENTRADO" qtde"

_nVolLeite:= _aSoroConce[1,2]//+_aSoroConce[2,2]+_aSoroConce[3,2]+_aSoroConce[4,2]
_nTotValor:= _aSoroConce[3,3]+_aSoroConce[4,3]
aAdd(_aSoroConce,{"CUSTO (FIFO) EFETIVO - SORO DE LEITE CONCENTRADO",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//05 - OK
_aCustoMP[3,2]:=(_nTotValor/_nVolLeite)//"SORO CONCENTRADO"

_aCusto04[5,2]:=_nVolLeite
_aCusto04[5,3]:=_nTotValor
_aCusto04[5,4]:=(_nTotValor/_nVolLeite)

// CREME DE LEITE
If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo CUSTO CREME C/ ICMS ...")
   ProcessMessages()
EndIf
_aTotias  := CusComICMS(_cFilis,"004")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aCremeLeit,{"CUSTO CREME C/ ICMS",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//01 - OK

_nTotValor:= _aTMGICMS[4,3]*(-1)//"004"
aAdd(_aCremeLeit,{"APROVEITAMENTO CREDITO ICMS ( - ) (obs.: Desconsiderado transf. entre filiais)",0,_nTotValor,(_nTotValor/_nVolLeite)})//02 - OK

_nTotValor:= _aCremeLeit[1,3]+_aCremeLeit[2,3]
aAdd(_aCremeLeit,{"CUSTO CREME S/ ICMS",0,_nTotValor,(_nTotValor/_nVolLeite)})//03  - OK

If ValType(_oRegua) = "O"
   _oRegua:IncRegua2("CMP-Lendo custo frete 2o. percurso s/ ICMS ...")
	ProcessMessages()
EndIf
_aTotias  := CusFret2P(_cFilis,"F;P;T","004")
_nVolLeite:= _aTotias[1]
_nTotValor:= _aTotias[2]
aAdd(_aCremeLeit,{"CUSTO FRETE 2o. PERCURSO (S/ ICMS)",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//04 - OK
//                                 2-Custo,3-Custo F,4-Frete,5-Qtde,6-Frete 2
//aAdd(_aCustoMP,{"CREME DE LEITE",0      ,0        ,0      ,0     ,0        })//01
_aCustoMP[4,3]:=(_nTotValor/_nVolLeite)//"CREME DE LEITE" custo do frete"
_aCustoMP[4,4]:=_nTotValor//"CREME DE LEITE" frete"
_aCustoMP[4,5]:=_nVolLeite//"CREME DE LEITE" qtde"

_nVolLeite:= _aCremeLeit[1,2]//+_aCremeLeit[2,2]+_aCremeLeit[3,2]+_aCremeLeit[4,2]
_nTotValor:= _aCremeLeit[3,3]+_aCremeLeit[4,3]
aAdd(_aCremeLeit,{"CUSTO (FIFO) EFETIVO - CREME DE LEITE",_nVolLeite,_nTotValor,(_nTotValor/_nVolLeite)})//05 - OK
_aCustoMP[4,2]:=(_nTotValor/_nVolLeite)//"CREME DE LEITE"

_aCusto04[6,2]:=_nVolLeite
_aCusto04[6,3]:=_nTotValor
_aCusto04[6,4]:=(_nTotValor/_nVolLeite)

If ValType(_oRegua) = "O"
   _oRegua:SetRegua2( 0 )
   _oRegua:IncRegua2("CMP - LIDO OK")
	ProcessMessages()
EndIf
If lSoPegaVlrs
   Return _aCustoMP
EndIf

//CUSTO MP  PASTA 1
aAdd( _AXML,' <Worksheet ss:Name="CUSTO MP">')
aAdd( _AXML,'  <Table ss:ExpandedColumnCount="6" ss:ExpandedRowCount="999999" x:FullColumns="1"')
aAdd( _AXML,'   x:FullRows="1" ss:DefaultRowHeight="15">')
aAdd( _AXML,'   <Column ss:Width="342.75"/>')
aAdd( _AXML,'   <Column ss:Width="89.25"/>')
aAdd( _AXML,'   <Column ss:Width="123"/>')
aAdd( _AXML,'   <Column ss:Width="87"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="63.75"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="97.5"/>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0" ss:Height="15.75">')
aAdd( _AXML,'    <Cell ss:MergeAcross="2" ss:StyleID="s65"><Data ss:Type="String">APURACAO DE CUSTOS MATERIA PRIMA  - UND. ' + FWFilialName( cEmpAnt , xFilial("ZL6") , 2 )  + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s65"><Data ss:Type="String">' + MESEXTENSO(MONTH(MV_PAR05)) + '/' + AllTrim(Str(YEAR(MV_PAR05))) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0" ss:Height="15.75">')
aAdd( _AXML,'    <Cell ss:StyleID="s66"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s66"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s66"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s66"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0" ss:Height="15.75">')
aAdd( _AXML,'    <Cell ss:StyleID="s68"><Data ss:Type="String">DESCRICAO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"><Data ss:Type="String">VOLUME</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"><Data ss:Type="String">CUSTO TOTAL</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s68"><Data ss:Type="String">CUSTO / L</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s70"><Data ss:Type="String">CUSTO OPERACIONAL DAS FILIAIS</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO OPERACIONAL</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aCustOpera[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aCustOpera[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aCustOpera[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">LEITE PROPRIO</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE PROPRIO - MIX</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
//NOVA LINHA ENTRO DEPOIS
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE POSTOS - MIX</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[4,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
//NOVA LINHA ENTRO DEPOIS
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 1o. PERCURSO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[2,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">INCLUSO NO MIX</Data></Cell>')//'+AllTrim(Str(_aLeiteProp[2,3]))+'
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (SEM ICMS)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[3,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s82"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO POSTO/FABRICA - LEITE PROPRIO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s84"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteProp[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">LEITE TERCEIROS</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE TERCEIROS (COM MG E COM ICMS) (A)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s91"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO EXCEDENTE MATERIA GORDA  ( - ) (B)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">APROVEITAMENTO CREDITO ICMS ( - ) (C) (obs.: Desconsiderado transf. entre filiais)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE TERCEIROS (SEM MG E SEM ICMS) (A) - (B) - (C) = (D)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">LEITE DIRETO P/ FABRICA SEM CUSTO DE FRETE (E)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (SEM ICMS) (F)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[6,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[6,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[6,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO EFETIVO LEITE TERCEIROS + FRETE (S/ MG e S/ICMS) (D) + (E) + (F)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s84"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[7,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[7,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">'+AllTrim(Str(_aLeiteTerc[7,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s94"><Data ss:Type="String">RESUMO GERAL - CUSTO LEITE</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE - PROPRIO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO LEITE - TERCEIROS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[2,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s82"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s95"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s96"><Data ss:Type="String">CUSTO (FIFO) LEITE IN-NATURA - TOTAL</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s97"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[3,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s98"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s99"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s101"><Data ss:Type="String">CUSTO EXC. MATERIA GORDA A TRANSPORTAR P/ CREME DE LEITE UHT</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s102"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s103"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s104"><Data ss:Type="Number">'+AllTrim(Str(_aResumoGer[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s106"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">SORO DE LEITE</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')//_aSoroLeite
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO C/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">APROVEITAMENTO CREDITO ICMS ( - )</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO S/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (S/ ICMS)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO (FIFO) EFETIVO - SORO DE LEITE</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s84"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">'+AllTrim(Str(_aSoroLeite[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">SORO DE LEITE PRE-CONCENTRADO</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')//_aSoroPreCo
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO PRE-CONCENTRADO C/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">APROVEITAMENTO CREDITO ICMS ( - )</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO PRE-CONCENTRADO S/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (S/ ICMS)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO (FIFO) EFETIVO - SORO DE LEITE PRE-CONCENTRADO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s84"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">'+AllTrim(Str(_aSoroPreCo[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">SORO DE LEITE CONCENTRADO</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')//_aSoroConce
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO CONCENTRADO C/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s77"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">APROVEITAMENTO CREDITO ICMS ( - )</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO SORO CONCENTRADO S/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (S/ ICMS)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO (FIFO) EFETIVO - SORO DE LEITE CONCENTRADO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s84"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">'+AllTrim(Str(_aSoroConce[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s107"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s100"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="s76"><Data ss:Type="String">CREME DE LEITE</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO CREME C/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s108"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[1,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data  ss:Type="Number">'+AllTrim(Str(_aCremeLeit[1,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data  ss:Type="Number">'+AllTrim(Str(_aCremeLeit[1,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">APROVEITAMENTO CREDITO ICMS ( - ) (obs.: Desconsiderado transf. entre filiais)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[2,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[2,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO CREME S/ ICMS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[3,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[3,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s109"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s110"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s110"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s111"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s71"><Data ss:Type="String">CUSTO FRETE 2o. PERCURSO (S/ ICMS)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s74"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[4,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s75"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[4,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s78"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s79"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s80"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s81"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">')
aAdd( _AXML,'    <Cell ss:StyleID="s83"><Data ss:Type="String">CUSTO (FIFO) EFETIVO - CREME DE LEITE</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s112"><Data ss:Type="Number">'+AllTrim(Str(_aCremeLeit[5,2]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s85"><Data  ss:Type="Number">'+AllTrim(Str(_aCremeLeit[5,3]))+'</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data  ss:Type="Number">'+AllTrim(Str(_aCremeLeit[5,4]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>') 

aAdd( _AXML,'  </Table>')
aAdd( _AXML,'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">')
aAdd( _AXML,'   <PageSetup>')
aAdd( _AXML,'    <Header x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <Footer x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.511811024"')
aAdd( _AXML,'     x:Right="0.511811024" x:Top="0.78740157499999996"/>')
aAdd( _AXML,'   </PageSetup>')
aAdd( _AXML,'   <Unsynced/>')
aAdd( _AXML,'   <Selected/>')
aAdd( _AXML,'   <Panes>')
aAdd( _AXML,'    <Pane>')
aAdd( _AXML,'     <Number>3</Number>')
aAdd( _AXML,'     <ActiveRow>2</ActiveRow>')
aAdd( _AXML,'    </Pane>')
aAdd( _AXML,'   </Panes>')
aAdd( _AXML,'   <ProtectObjects>False</ProtectObjects>')
aAdd( _AXML,'   <ProtectScenarios>False</ProtectScenarios>')
aAdd( _AXML,'  </WorksheetOptions>')
aAdd( _AXML,' </Worksheet>')

Return _AXML 

/*
===============================================================================================================================
Programa----------: MEST9PEstoqueMP()
Autor-------------: Alex Wallauer
Data da Criacao---: 20/06/2018
Descricao---------: Monta Pasta Materia prima do excel
Parametros--------: _AXML,_aZeNew,lSoPegaVlrs,_oRegua
Retorno-----------: _AXML
===============================================================================================================================
*/
Static Function MEST9PEstoqueMP(_AXML,_aZeNew,lSoPegaVlrs,_oSelf)

Local _nQtdSin  :=0 , _nI   , _nPos
Local _cSegUni  :="N"
Local _cEstAnt  :="1"
Local _cGrpCus  :="" 
Local _cLocais  :="" 
Local _aEstoqFim:={}
Local _aEntradas:={}
Local _aConsumo :={}
Local _aVendas  :={}
Local _aTrans   :={}
Local _aOutros  :={}
Local _aPerdas  :={}
Local _aDiferenc:={}
Local _cFiliais :=""
Local _nPosTotal:=0
Local _nPosGeral:=0
Local _aEstoque :={0,0,0}  //Grupo Custo:  "000001"
Default lSoPegaVlrs := .F.
Private _cFilis :=""

aAdd(_aEntradas,{00,"TOTAL ENTRADAS MATERIA PRIMA DO MES"})// (B) 	        //NN  = _azeNew[_nI][07] = Grupo Custo:  "000002" SOMATORIO DO GRUPO
_nPosTotal:=Len(_aEntradas)
aAdd(_aEntradas,{00,"TOTAL MATERIA PRIMA DO MES (A)+(B)=(C)"})              //NN  SOMATORIO DOS ANTERIORES
_nPosGeral:=Len(_aEntradas)

aAdd(_aConsumo ,{00,"SALDO PARCIAL (C)-(D) = (E)","ULTIMO","0"})	        //NN  SALDO PARCIAL (C)+(D)+(E) = (F)      SOMATORIO DO GRUPO
_nTotConsumo:=Len(_aConsumo)

aAdd(_aVendas  ,{00,"TOTAL VENDAS LEITE RESFRIADO DO MES (F)"})             //01 //_azeNew[_nI][08] = Grupo Custo: "000004"  SOMATORIO DO GRUPO

aAdd(_aTrans   ,{00,"TOTAL DE TRANSFERENCIAS (G)"})			                //01 //_azeNew[_nI][08] = Grupo Custo: "000005"  SOMATORIO DO GRUPO //TOTAL DE TRANSFERENCIAS (G)
aAdd(_aTrans   ,{00,"SALDO PARCIAL  (E)-(F)-(G) = (H)"})	                //01 //SALDO PARCIAL  (E)-(F)-(G) = (H)

aAdd(_aEstoqFim,{00,"TOTAL ESTOQUE FINAL DO MES (I)"})                      //NN SOMATORIO DO GRUPO // TOTAL ESTOQUE FINAL DO MES (I)
_nTotEstoqFim:=Len(_aEstoqFim)
aAdd(_aEstoqFim,{00,"SALDO PARCIAL (H)-(I) = (J)"})                         //NN CALCULO DO SALDO // SALDO PARCIAL  (H)-(I) = (J)
_nTotEFSalPar:=Len(_aEstoqFim)

aAdd(_aOutros,{00,"DESCONTO FRETISTA FILIAIS"})                             //01 //_azeNew[_nI][08] = Grupo Custo: "000007"
aAdd(_aOutros,{00,"PERDAS FILIAIS (RESPONSABILIDADE FABRICA)"})             //02
aAdd(_aOutros,{00,"DOACOES FILIAIS"})                                       //03
aAdd(_aOutros,{00,"SAIDAS PRODUTOR"})                                       //04
aAdd(_aOutros,{00,"TOTAL OUTRAS SAIDAS (K)"})                               //05//TOTAL OUTRAS SAIDAS (K) - SÓ SOMATORIA
_nTotOuSalPar:=Len(_aOutros)

aAdd(_aPerdas,{00,"PERDAS DE LEITE/CREME"})                                 //01 //_azeNew[_nI][08] = Grupo Custo: "000008"
aAdd(_aPerdas,{00,"PERDAS SORO DE LEITE"})                                  //02
aAdd(_aPerdas,{00,"TOTAL PERDAS (L)"})                                      //03 // TOTAL PERDAS        (L) - SÓ SOMATORIA
_nTotPeSalPar:=Len(_aPerdas)

aAdd(_aDiferenc,{00,"DIFERENCA (J)-(K)-(L)"}) 			                    //01 //_azeNew[_nI][08] = Grupo Custo: "000009"//NÃO TEM MAIS ESSA REGRA DESDE 04/02/219

If ValType(_oSelf) = "O"
   _oRegua:=_oSelf
EndIf

If ValType(_oRegua) = "O"
   _oRegua:SetRegua2( Len(_azeNew) )
EndIf

For _nI := 1 To Len(_azeNew)//Rodas os codigos '000004' 
	If ValType(_oRegua) = "O"
		_oRegua:IncRegua2("RMP-Lendo "+_azeNew[_nI][07]+"...")
		ProcessMessages()
	EndIf

	If _azeNew[_nI][02] <> "000004" //AllTrim(ZL6T->ZL6_TPCUS)
		Loop
	EndIf

	If _azeNew[_nI][08] = "000001" //_azeNew[_nI][20] = "8" //ESTOQUE INICIAL FIXO
		_nQtdSin:=_azeNew[_nI][10]
		_cFilis := AllTrim(_azeNew[_nI][22])//Essa variavel usa na função MEST009SB9()
		If _nQtdSin = 0 .And. !_azeNew[_nI][21] .And. !Empty(_azeNew[_nI][15])
			_cLocais:= MEST9Locais()
			_aRet   := MEST009SB9(_azeNew[_nI][15],_cSegUni,_cEstAnt,_cGrpCus,,_cLocais)  //valores de estoque anterior
			_nQtdSin:= _aRet[1][1]
		EndIf   
		If Empty(_cFilis)
			_aEstoque[1] += _nQtdSin //ESTOQUE INICIAL DO MES
		Else
			_cFiliais:=StrTran(_cFilis,";",",")
			_aEstoque[2] += _nQtdSin//ESTOQUE INICIAL DAS FILIAIS ['+_cFiliais+'] DO MES
		EndIf   

	ElseIf _azeNew[_nI][08] = "000002" //_azeNew[_nI][20] = "1" ou _azeNew[_nI][20] = "3"//ENTRADAS VARIADO
		aAdd(_aEntradas,{_azeNew[_nI][10],_azeNew[_nI][07]})
		_aEntradas[_nPosTotal,1]+=_azeNew[_nI][10]
	ElseIf _azeNew[_nI][08] = "000003" //_azeNew[_nI][20] = "1" ou _azeNew[_nI][20] = "3"//CONSUMO
						//_nQtdSin         , ZL6->ZL6_DSUBEV ,_cordem  03     ,ZL6->ZL6_REGRA 04
		aAdd(_aConsumo,{ (_azeNew[_nI][10]) , _azeNew[_nI][07],_azeNew[_nI][14],_azeNew[_nI][13] })
		_aConsumo[_nTotConsumo,1]+=_azeNew[_nI][10]//SALDO PARCIAL
	ElseIf _azeNew[_nI][08] = "000004" //VENDAS
		aAdd(_aVendas,{_azeNew[_nI][10],_azeNew[_nI][07]})
		_aVendas[01,1]+=_azeNew[_nI][10]//TOTAL VENDAS LEITE RESFRIADO DO MES
	ElseIf _azeNew[_nI][08] = "000005" // TRANSFERENCIA
		_azeNew[_nI][10]:=(_azeNew[_nI][10])
		aAdd(_aTrans,{_azeNew[_nI][10],_azeNew[_nI][07]})
		_aTrans[01,1]+=_azeNew[_nI][10]//TOTAL DE TRANSFERENCIAS 
	ElseIf _azeNew[_nI][08] = "000006"//_azeNew[_nI][20] =  "E"  //////////// ESTOQUE FINAL  ////////////////////////////////////////////////// 
		aAdd(_aEstoqFim,{_azeNew[_nI][10],_azeNew[_nI][07]})
		_aEstoqFim[_nTotEstoqFim,1]+=_azeNew[_nI][10]
	ElseIf _azeNew[_nI][08] = "000007" //////////// OUTROS  FIXO ////////////////////////////////////////////////// 
		_nPos:=aScan(_aOutros,{|E| E[2] == _azeNew[_nI][07] } )
		If _nPos <> 0
			_aOutros[_nPos,1]+=_azeNew[_nI][10]
			_aOutros[_nTotOuSalPar,1]+=_azeNew[_nI][10]
		EndIf
	ElseIf _azeNew[_nI][08] = "000008" //////////// PERDAS  FIXO ////////////////////////////////////////////////// 
		_nPos:=aScan(_aPerdas,{|E| E[2] == _azeNew[_nI][07] } )
		If _nPos <> 0
			_aPerdas[_nPos,1]+=_azeNew[_nI][10]
			_aPerdas[_nTotPeSalPar,1]+=_azeNew[_nI][10]
		EndIf
	EndIf
Next

_nI := 1

_aConsAux := _aConsumo
_aConsumo := {}

_cTesteA:="Valor;Produto;Ordem;Regra"+CRLF+"ANTES:"+CRLF
_cTesteD:="DEPOIS:"+CRLF
For _nI := 1 To Len(_aConsAux) 
    _cTesteA+=Str(_aConsAux[_nI][01],20,8)+";"+_aConsAux[_nI][02]+";"+_aConsAux[_nI][03]+";"+_aConsAux[_nI][04]+CRLF
	_np := aScan(_aConsumo,{|C|C[03]==_aConsAux[_nI][03] }) //ZL6_ORDEM

	If _aConsAux[_nI][4] == "2" .And. _np > 0//ZL6_REGRA
	   _aConsumo[_np][1] += _aConsAux[_nI][1]
	Else
		aAdd(_aConsumo,_aConsAux[_nI])
	EndIf
Next
For _nI := 1 To Len(_aConsumo) 
    _cTesteD+=Str(_aConsumo[_nI][01],20,8)+";"+_aConsumo[_nI][02]+";"+_aConsumo[_nI][03]+";"+_aConsAux[_nI][04]+CRLF
Next
_cTeste:=StrTran(_cTesteA+_cTesteD,".",",")
_cFileNome:=_cdir+"MEST009_CONSUMO_RESUMIDO_"+DToS(Date())+"_"+StrTran(TIME(),":","_")+".CSV"
MemoWrite(_cFileNome,_cTeste)

// CALCULOS DOS TOTAIS
_aEstoque[3]               :=_aEstoque[1]+_aEstoque[2]                             //TOTAL ESTOQUE INICIAL DE LEITE DO MES (A)
_aEntradas[_nPosGeral,1]   :=_aEstoque[3]+_aEntradas[_nPosTotal,1]                 //TOTAL MATERIA PRIMA DO MES (A)+(B)=(C)
_aConsumo[_nTotConsumo,1]  :=_aEntradas[_nPosGeral,1]-_aConsumo[_nTotConsumo,1]    //SALDO PARCIAL (C)-(Tot. Consumos) = (E)
_aTrans[02,1]              :=_aConsumo[_nTotConsumo,1]-_aVendas[01,1]-_aTrans[01,1]//SALDO PARCIAL  (E)-(F)-(G) = (H)
_aEstoqFim[_nTotEFSalPar,1]:=_aTrans[02,1]-_aEstoqFim[_nTotEstoqFim,1]             //SALDO PARCIAL  (H)-(I) = (J)
_aDiferenc[01,01]:=_aEstoqFim[_nTotEFSalPar,1]-_aOutros[_nTotOuSalPar,01]-_aPerdas[_nTotPeSalPar,01]//DIFERENCA (J)-(K)-(L)
// CALCULOS DOS TOTAIS

If ValType(_oRegua) = "O"
   _oRegua:SetRegua2(0)
   _oRegua:IncRegua2("RMP - LIDO OK")
   ProcessMessages()
EndIf

If lSoPegaVlrs
   Return _aDiferenc[01,01]
EndIf

aAdd( _AXML,' <Worksheet ss:Name="ESTOQUE MP">') //ESTOQUE MP

aAdd( _AXML,'  <Table ss:ExpandedColumnCount="6" ss:ExpandedRowCount="999999" x:FullColumns="1"')
aAdd( _AXML,'   x:FullRows="1" ss:DefaultRowHeight="15">')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="387.75"/>')
aAdd( _AXML,'   <Column ss:Index="4" ss:AutoFitWidth="0" ss:Width="18.75"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="20.25"/>')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="83.25"/>')
aAdd( _AXML,'   <Row>')

aAdd( _AXML,'    <Cell ss:MergeAcross="4" ss:StyleID="s113"><Data ss:Type="String">RESUMO ENTRADAS DE MATERIAS PRIMAS - UND. ' + FWFilialName( cEmpAnt , xFilial("ZL6") , 2 )+'</Data></Cell>')

aAdd( _AXML,'    <Cell ss:StyleID="s144"><Data ss:Type="String">' + MESEXTENSO(MONTH(MV_PAR05)) + '/' + AllTrim(Str(YEAR(MV_PAR05))) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s115"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s116"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s116"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s116"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s116"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s116"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s67"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:MergeAcross="4" ss:StyleID="s129"><Data ss:Type="String">HISTORICO</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s145"><Data ss:Type="String">QUANTIDADE</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s146"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s135"><Data ss:Type="String">ESTOQUE</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s146"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">ESTOQUE INICIAL DO MES</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s136"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aEstoque[1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">ESTOQUE INICIAL DAS FILIAIS ['+_cFiliais+'] DO MES</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s136"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aEstoque[2] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s136"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL ESTOQUE INICIAL DE LEITE DO MES (A)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s140"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aEstoque[3] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s140"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s135"><Data ss:Type="String">ENTRADAS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

For _nI := 3 To Len(_aEntradas)
    aAdd( _AXML,'   <Row>')
    aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">' + AllTrim(_aEntradas[_nI,2]) + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s142"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aEntradas[_nI,1] )) + '</Data></Cell>')
    aAdd( _AXML,'   </Row>')      
Next

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s136"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL ENTRADAS MATERIA PRIMA DO MES (B)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s140"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aEntradas[_nPosTotal,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s136"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL MATERIA PRIMA DO MES (A)+(B) = (C)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s140"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aEntradas[_nPosGeral,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

For _nI := 2 To Len(_aConsumo)
    aAdd( _AXML,'   <Row>')
    aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">' + AllTrim(_aConsumo[_nI,2]) + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s142"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aConsumo[_nI,1] )) + '</Data></Cell>')
    aAdd( _AXML,'   </Row>')      
Next

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">SALDO PARCIAL (C)-(Tot. Consumos) = (E)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aConsumo[_nTotConsumo,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
For _nI := 2 To Len(_aVendas)
    aAdd( _AXML,'   <Row>')
    aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">' + AllTrim(_aVendas[_nI,2]) + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s142"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aVendas[_nI,1] )) + '</Data></Cell>')
    aAdd( _AXML,'   </Row>')      
Next
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL VENDAS LEITE RESFRIADO DO MES (F)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aVendas[01,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

For _nI := 3 To Len(_aTrans)
    aAdd( _AXML,'   <Row>')
    aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">' + AllTrim(_aTrans[_nI,2]) + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s142"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' + AllTrim(Str( _aTrans[_nI,1] )) + '</Data></Cell>')
    aAdd( _AXML,'   </Row>')      
Next

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL DE TRANSFERENCIAS (G)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aTrans[01,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row>')                                                     
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">SALDO PARCIAL (E)-(F)-(G) = (H)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aTrans[02,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')

For _nI := 3 To Len(_aEstoqFim)
    aAdd( _AXML,'   <Row>')
    aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">' + AllTrim(_aEstoqFim[_nI,2]) + '</Data></Cell>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
    aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">' +  AllTrim(Str( _aEstoqFim[_nI,1] )) + '</Data></Cell>')
    aAdd( _AXML,'   </Row>')      
Next

aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL ESTOQUE FINAL DO MES (I)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aEstoqFim[_nTotEstoqFim,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">SALDO PARCIAL (H)-(I) = (J) </Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">' + AllTrim(Str( _aEstoqFim[_nTotEFSalPar,1] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">DESCONTO FRETISTA FILIAIS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aOutros[01,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">PERDAS FILIAIS (RESPONSABILIDADE FABRICA)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aOutros[02,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">DOACOES FILIAIS</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aOutros[03,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">SAIDAS PRODUTOR</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aOutros[04,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL OUTRAS SAIDAS (K)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">'+AllTrim(Str( _aOutros[_nTotOuSalPar,01] ))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">PERDA DE LEITE/CREME</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aPerdas[01,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"><Data ss:Type="String">PERDAS SORO DE LEITE</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"><Data ss:Type="Number">'+AllTrim(Str(_aPerdas[02,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">TOTAL PERDAS (L)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s139"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">'+AllTrim(Str(_aPerdas[_nTotPeSalPar,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s132"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s147"/>')
aAdd( _AXML,'   </Row>')
aAdd( _AXML,'   <Row>')
aAdd( _AXML,'    <Cell ss:StyleID="s138"><Data ss:Type="String">DIFERENCA '+If(_aDiferenc[01,01]>0,"A CUSTEAR",If(_aDiferenc[01,01]<0,"A COMPENSAR",""))+' (J)-(K)-(L)</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s133"/>')
aAdd( _AXML,'    <Cell ss:StyleID="s148"><Data ss:Type="Number">'+AllTrim(Str(_aDiferenc[01,01]))+'</Data></Cell>')
aAdd( _AXML,'   </Row>')

aAdd( _AXML,'  </Table>')
aAdd( _AXML,'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">')
aAdd( _AXML,'   <PageSetup>')
aAdd( _AXML,'    <Header x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <Footer x:Margin="0.31496062000000002"/>')
aAdd( _AXML,'    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.511811024"')
aAdd( _AXML,'     x:Right="0.511811024" x:Top="0.78740157499999996"/>')
aAdd( _AXML,'   </PageSetup>')
aAdd( _AXML,'   <Print>')
aAdd( _AXML,'    <ValidPrinterInfo/>')
aAdd( _AXML,'    <PaperSizeIndex>9</PaperSizeIndex>')
aAdd( _AXML,'    <HorizontalResolution>600</HorizontalResolution>')
aAdd( _AXML,'    <VerticalResolution>600</VerticalResolution>')
aAdd( _AXML,'   </Print>')
aAdd( _AXML,'   <Panes>')
aAdd( _AXML,'    <Pane>')
aAdd( _AXML,'     <Number>3</Number>')
aAdd( _AXML,'     <ActiveRow>2</ActiveRow>')
aAdd( _AXML,'    </Pane>')
aAdd( _AXML,'   </Panes>')
aAdd( _AXML,'   <ProtectObjects>False</ProtectObjects>')
aAdd( _AXML,'   <ProtectScenarios>False</ProtectScenarios>')
aAdd( _AXML,'  </WorksheetOptions>')
aAdd( _AXML,' </Worksheet>')

aAdd( _AXML,'</Workbook>')

Return _AXML 

/*
===============================================================================================================================
Programa----------: MEST94Plan()
Autor-------------: Alex Wallauer
Data da Criacao---: 05/07/2018
Descricao---------: Retorna o LayOut da Planilha 4 "04-Espelho Composicao dos Custos "
Parametros--------: _aCusto04
Retorno-----------: _axml 
===============================================================================================================================
*/
Static Function MEST94Plan(_aCusto04)

Local _AXML      := {}
Local _nI 
Local _cArq01    := "\data\italac\mest009\MEST009_PLAN_04.txt"

//Definições
If FT_FUSE(_cArq01) == -1
	U_ITMsg("Não foi possível abrir o arquivo: "+_cArq01,"Arquivo inválido","Favor verificar se o arquivo se esta correto.",1)
	Return _AXML
EndIf

FT_FGOTOP()//PONTO NO TOPO

If FT_FLASTREC() == 0
	U_ITMsg("O arquivo "+_cArq01+" não possui dados.","Arquivo inválido","Favor verificar se o arquivo se esta correto.",1)
	Return _AXML
EndIf

While !FT_FEof()  //FACA ENQUANTO NAO For FIM DE ARQUIVO
	_cLinha:=FT_FREADLN()
	If !Empty(_cLinha)
		aAdd(_AXML,_cLinha)
	EndIf
	FT_FSKIP()   //próximo registro no arquivo txt
EndDo

FT_FUSE()//Fecha o arquivo

aAdd( _AXML,'<Worksheet ss:Name="ESPELHO CUSTOS">                                                                                                   ')
aAdd( _AXML,'  <Table ss:ExpandedColumnCount="7" ss:ExpandedRowCount="999999" x:FullColumns="1"                                                         ')
aAdd( _AXML,'   x:FullRows="1" ss:DefaultRowHeight="15">                                                                                            ')
aAdd( _AXML,'   <Column ss:Index="4" ss:AutoFitWidth="0" ss:Width="174.75"/>                                                                        ')
aAdd( _AXML,'   <Column ss:AutoFitWidth="0" ss:Width="108.75" ss:Span="2"/>                                                                         ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')

aAdd( _AXML,'    <Cell ss:MergeAcross="4" ss:StyleID="s65"><Data ss:Type="String">ESPELHO DA COMPOSICAO DOS CUSTOS - UND. ' + FWFilialName( cEmpAnt , xFilial("ZL6") , 2 )  + '</Data></Cell> ')
aAdd( _AXML,'    <Cell ss:StyleID="s102"><Data ss:Type="String">' + MESEXTENSO(MONTH(MV_PAR05)) + '/' + AllTrim(Str(YEAR(MV_PAR05))) + '</Data></Cell>                                                             ')

aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="6" ss:StyleID="s67"/>                                                                                        ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891136"><Data ss:Type="String">HISTORICO</Data></Cell>                                    ')
aAdd( _AXML,'    <Cell ss:StyleID="s78"><Data ss:Type="String">QUANTIDADES</Data></Cell>                                                            ')
aAdd( _AXML,'    <Cell ss:StyleID="s78"><Data ss:Type="String">VALOR</Data></Cell>                                                                  ')
aAdd( _AXML,'    <Cell ss:StyleID="s78"><Data ss:Type="String">PARTIC.</Data></Cell>                                                                ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891156"><Data ss:Type="String">' + AllTrim(_aCusto04[1,1] ) + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[1,2] )) + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[1,3] )) + '</Data></Cell>')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[1,4] )) + '</Data></Cell>')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s91"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891176"><Data ss:Type="String">' + AllTrim(_aCusto04[2,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[2,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[2,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[2,4] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891196"><Data ss:Type="String">' + AllTrim(_aCusto04[3,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[3,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[3,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[3,4] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891304"><Data ss:Type="String">' + AllTrim(_aCusto04[4,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[4,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[4,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[4,4] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891324"><Data ss:Type="String">' + AllTrim(_aCusto04[5,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[5,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[5,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[5,4] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891344"><Data ss:Type="String">' + AllTrim(_aCusto04[6,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="String">' + AllTrim(TRANSFORM(_aCusto04[6,2], "@E 999,999,999,999" )) + ' KG</Data></Cell>   ')//GAMBIS
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[6,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s88"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[6,4] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891364"><Data ss:Type="String">' + AllTrim(_aCusto04[7,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[7,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[7,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891384"><Data ss:Type="String">' + AllTrim(_aCusto04[8,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[8,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[8,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891404"><Data ss:Type="String">' + AllTrim(_aCusto04[9,1] ) + '</Data></Cell>             ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[9,2] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'    <Cell ss:StyleID="s92"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[9,3] )) + '</Data></Cell>                                 ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s89"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s90"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891512"><Data ss:Type="String">' + AllTrim(_aCusto04[10,1] ) + '</Data></Cell>            ')
aAdd( _AXML,'    <Cell ss:StyleID="s86"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[10,2] )) + '</Data></Cell>                                ')
aAdd( _AXML,'    <Cell ss:StyleID="s95"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[10,3] )) + '</Data></Cell>                                ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s96"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:MergeAcross="6" ss:StyleID="s98"><Data ss:Type="String">CUSTO DE &quot;EXPEDICAO&quot; PRODUTOS ITALAC</Data></Cell>      ')
aAdd( _AXML,'   </Row>                                                                                                                              ')
aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                          ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                           ')
aAdd( _AXML,'   </Row>                                                                                                                              ')

For _nI := 11 To Len(_aCusto04)
	aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                      ')
	aAdd( _AXML,'    <Cell ss:MergeAcross="3" ss:StyleID="m136891552"><Data ss:Type="String">' + AllTrim(_aCusto04[_nI,1] ) + '</Data></Cell>       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s86"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[_nI,2] )) + '</Data></Cell>                           ')
	aAdd( _AXML,'    <Cell ss:StyleID="s87"><Data ss:Type="Number">' + AllTrim(Str( _aCusto04[_nI,3] )) + '</Data></Cell>                           ')
	aAdd( _AXML,'    <Cell ss:StyleID="s88" ss:Formula="=If(RC[-1]=0,0,RC[-1]/RC[-2])"><Data                                                        ')
	aAdd( _AXML,'      ss:Type="Number">0</Data></Cell>                                                                                             ')
	aAdd( _AXML,'   </Row>                                                                                                                          ')
	aAdd( _AXML,'   <Row ss:AutoFitHeight="0">                                                                                                      ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'    <Cell ss:StyleID="s63"/>                                                                                                       ')
	aAdd( _AXML,'   </Row>                                                                                                                          ')
Next

aAdd( _AXML,'  </Table>                                                                                                                             ')
aAdd( _AXML,'  <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">                                                                    ')
aAdd( _AXML,'   <PageSetup>                                                                                                                         ')
aAdd( _AXML,'    <Header x:Margin="0.31496062000000002"/>                                                                                           ')
aAdd( _AXML,'    <Footer x:Margin="0.31496062000000002"/>                                                                                           ')
aAdd( _AXML,'    <PageMargins x:Bottom="0.78740157499999996" x:Left="0.511811024"                                                                   ')
aAdd( _AXML,'     x:Right="0.511811024" x:Top="0.78740157499999996"/>                                                                               ')
aAdd( _AXML,'   </PageSetup>                                                                                                                        ')
aAdd( _AXML,'   <Unsynced/>                                                                                                                         ')
aAdd( _AXML,'   <Print>                                                                                                                             ')
aAdd( _AXML,'    <ValidPrinterInfo/>                                                                                                                ')
aAdd( _AXML,'    <PaperSizeIndex>9</PaperSizeIndex>                                                                                                 ')
aAdd( _AXML,'    <HorizontalResolution>600</HorizontalResolution>                                                                                   ')
aAdd( _AXML,'    <VerticalResolution>600</VerticalResolution>                                                                                       ')
aAdd( _AXML,'   </Print>                                                                                                                            ')
aAdd( _AXML,'   <Selected/>                                                                                                                         ')
aAdd( _AXML,'   <Panes>                                                                                                                             ')
aAdd( _AXML,'    <Pane>                                                                                                                             ')
aAdd( _AXML,'     <Number>3</Number>                                                                                                                ')
aAdd( _AXML,'     <ActiveRow>9</ActiveRow>                                                                                                          ')
aAdd( _AXML,'     <RangeSelection>R10C1:R10C4</RangeSelection>                                                                                      ')
aAdd( _AXML,'    </Pane>                                                                                                                            ')
aAdd( _AXML,'   </Panes>                                                                                                                            ')
aAdd( _AXML,'   <ProtectObjects>False</ProtectObjects>                                                                                              ')
aAdd( _AXML,'   <ProtectScenarios>False</ProtectScenarios>                                                                                          ')
aAdd( _AXML,'  </WorksheetOptions>                                                                                                                  ')
aAdd( _AXML,' </Worksheet>                                                                                                                          ')
aAdd( _AXML,'</Workbook>                                                                                                                            ')

Return _AXML

/*
===============================================================================================================================
Programa----------: MEST9Locais()
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2018
Descricao---------: Devolve todos os armazens cadastrados 
Parametros--------: Nenhum
Retorno-----------: Locais
===============================================================================================================================
*/
Static Function MEST9Locais()

Local _cQuery :="" 
Local _cLocais:="" 

_cQuery	+= " SELECT NNR_CODIGO FROM " + RetSqlName("NNR") + " NNR WHERE "
_cQuery	+= "								      			  NNR.NNR_CODIGO NOT IN ('40','36','37') AND "
_cQuery	+= "								      			  NNR.D_E_L_E_T_ = ' ' AND "
_cQuery	+= "								      			  NNR.NNR_FILIAL = '" + xFilial("NNR")+"'"

MPSysOpenQuery( _cQuery , "TRBLocs" ) 

While TRBLocs->(!Eof())
	_cLocais+=TRBLocs->NNR_CODIGO+";"
	TRBLocs->(DBSkip())
EndDo
TRBLocs->(DBCloseArea())

Return _cLocais

/*
===============================================================================================================================
Programa----------: MEST9PLAN()
Autor-------------: Alex Wallauer
Data da Criacao---: 04/07/2018
Descricao---------: Função usada no ITALACXFUN.PRW - F3: LSTME9
Parametros--------: Nenhum
Retorno-----------: Planilhas disponiveis para Geração
===============================================================================================================================*/
User Function MEST9PLAN()

Local _aPlans:={}

aAdd( _aPlans , "01-Operacional - PA,  Grupos (000001/000002/000003)            ")
aAdd( _aPlans , "02-Custo / Estoque - MP,  Grupos (000004/000005), Depende do 01")
aAdd( _aPlans , "03-Demonstrativo do Estoque Final,  Grupo (000006)             ")
aAdd( _aPlans , "04-Espelho Composicao dos Custos, Depende do 01 e 02           ")

Return _aPlans

/*
===============================================================================================================================
Programa----------: MEST9Info()
Autor-------------: Alex Wallauer
Data da Criacao---: 10/07/2018
Descricao---------: Função usada no ITALACXFUN.PRW - F3: LSTMT9 / U_MEST9Info(ZL6->ZL6_OBSERV)
Parametros--------: Nenhum
Retorno-----------: Tipos do campo CAMPO ZL6_OBSERV Informação 
===============================================================================================================================*/
User Function MEST9Info(cTipo)//U_MEST9Info("ACOLS")

Local _aTipos:={},nPos
Default cTipo:=" "
//ANTIGO: 1=NOTA ENTRADA;2=NOTA SAIDA;3=MOVIMENTOS INTERNOS;4=FINANCEIRO;5=PERDAS;6=MO;7=HE;8=SALDO INICIAL;9=GESTAO LEITE;A=FRETE MP
//NOVO B: 1=NF ENTRADA;2=NF SAIDA;3=MOVIMENTOS INTERNOS;4=FINANCEIRO;5=PERDAS;6=MO;7=HE;8=SALDO INICIAL;9=GESTAO LEITE;A=FRETE MP;B=MANUAL
//NOVO E: 1=NFE;2=NFS;3=MOV INT;4=FIN;5=PERDAS;6=MO;7=HE;8=SLD INI;9=GLT;A=FRETE MP;B=MANUAL;C=NFE + ST;D=FECH CUSTO GER;E=ESTOQ FINAL
aAdd( _aTipos , "1-NOTA ENTRADA              " )
aAdd( _aTipos , "2-NOTA SAIDA                " )
aAdd( _aTipos , "3-MOVIMENTOS INTERNOS       " )
aAdd( _aTipos , "4-FINANCEIRO                " )
aAdd( _aTipos , "5-PERDAS                    " )
aAdd( _aTipos , "6-FOLHA DE PAGAMENTO        " )
aAdd( _aTipos , "7-HORA EXTRA                " )
aAdd( _aTipos , "8-SALDO INICIAL             " )
aAdd( _aTipos , "9-GESTAO DE LEITE           " )//X
aAdd( _aTipos , "A-FRETE MATERIA PRIMA       " )
aAdd( _aTipos , "B-MANUAL                    " )
aAdd( _aTipos , "C-NFE + SITUACAO TRIBUTARIA " )//X
aAdd( _aTipos , "D-FECH CUSTO GERRENCIAL M.A." )
aAdd( _aTipos , "E-ESTOQUE FINAL             " )
aAdd( _aTipos , "F-EXCEDENTE MATERIA GORDA   " )
If cTipo = " "
   Return _aTipos
Else
	If cTipo = "BROWSES" .And. (Type("M->ZL6_TPCUS") <> "C"  .Or. !Empty(M->ZL6_TPCUS))
		cTipo:=ZL6->ZL6_OBSERV
	EndIf   
	If (nPos:=aScan(_aTipos,{|T| Upper(LEFT(T,1)) == Upper(cTipo) } )) <> 0
		Return SubStr(_aTipos[nPos],3)
	Else
		Return "       "
	EndIf   
EndIf

/*
===============================================================================================================================
Programa----------: VolLeite(()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/08/2018
Descrição---------: Retorna volume de leite (ZLD)
Parametros--------: _nSetor: Código do Setor
Retorno-----------: _nTotal	: Total do volume de leite
===============================================================================================================================*/
Static Function VolLeite( _cSetor )

Local _aArea	:= FWGetArea()
Local _cAlias	:= GetNextAlias()
Local _cQuery	:= ''
Local _nTotal	:= 0

If Empty(_cSetor)
   Return _nTotal 
EndIf

_cQuery := " SELECT "
_cQuery += " 		SUM(ZLD_QTDBOM) AS TBOM "
_cQuery += " FROM  "+ RETSQLNAME( 'ZLD' ) +" ZLD "
_cQuery += " WHERE ZLD_SETOR  IN " + FormatIn(AllTrim(_cSetor),";")
_cQuery += " AND ZLD_DTCOLE BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery += " AND ZLD.D_E_L_E_T_ = ' ' "

MPSysOpenQuery( _cQuery , _cAlias ) 

If (_cAlias)->( !Eof() )
	_nTotal  := (_cAlias)->TBOM
EndIf

(_cAlias)->( DBCloseArea() )

FWRestArea( _aArea )

Return _nTotal 

/*
===============================================================================================================================
Programa----------: GetVlrMix
Autor-------------: Alex Wallauer
Data da Criacao---: 23/08/2018
Descrição---------: Retorna total de movimentos na ZLF de determinado evento
Parametros--------: _cSetor  - Setor a ser considerado
Retorno-----------: _nTotal	: Total do volume de leite
===============================================================================================================================*/
Static Function GetVlrMix( _cSetor  )

Local cArea		:= FWGetArea()
Local cAliasLF	:= GetNextAlias()
Local _nTotal	:= 0

If Empty(_cSetor)
   Return _nTotal 
EndIf

// Obtendo movimentos na ZLF do grupo corrente                                  |
cQuery := " SELECT SUM( Case WHEN ZLF.ZLF_DEBCRE = 'C' THEN ZLF.ZLF_TOTAL Else ZLF.ZLF_TOTAL * -1 END ) AS TOTAL "
cQuery += " FROM "+ RetSqlName("ZLF") +" ZLF "
cQuery += " WHERE D_E_L_E_T_	= ' ' "
cQuery += "  AND ZLF.ZLF_DTINI BETWEEN '" + DToS(MV_PAR05) + "' AND '"+ DToS(MV_PAR06) +"' "
cQuery += "  AND ZLF.ZLF_DTFIM BETWEEN '" + DToS(MV_PAR05) + "' AND '"+ DToS(MV_PAR06) +"' "
cQuery += "  AND ZLF_SETOR IN " + FormatIn(AllTrim(_cSetor),";")
cQuery += "  AND EXISTS ( SELECT ZL8.ZL8_COD "
cQuery += "              FROM "+ RetSqlName("ZL8") +" ZL8 "
cQuery += "              WHERE ZL8.D_E_L_E_T_ = ' '  "
cQuery += "              AND ZL8.ZL8_FILIAL = ZLF.ZLF_FILIAL "
cQuery += "              AND ZL8.ZL8_COD    = ZLF.ZLF_EVENTO "
cQuery += "              AND ZL8.ZL8_MIX    = 'S' ) "

MPSysOpenQuery( cQuery , cAliasLF ) 

If (cAliasLF)->( !Eof() )
   _nTotal:= (cAliasLF)->TOTAL
EndIf
(cAliasLF)->( DBCloseArea() )

FWRestArea(cArea)

Return( _nTotal )

/*
===============================================================================================================================
Programa----------: CusFret2P
Autor-------------: Alex Wallauer
Data da Criacao---: 23/08/2018
Descrição---------: Retorna o total CUSTO FRETE 2º PERCURSO (SEM ICMS)
------------------: Baseado no RGLT013 - Recepção do Leite de Terceiros - Fatura de Frete
Parametros--------: _cFilis , _cTipos: F=LEITE FILIAIS, T=LEITE TERCEIRO, P=PLATAFORMA
------------------: _cGrpProd: 001 - LEITE IN-NATURA, 002 - SORO LIQUIDO, 003 - SORO CONCENTRADO, 004 - CREME
Retorno-----------: _aRet: {Volume,Valor}
===============================================================================================================================*/
Static Function CusFret2P(_cFiliais,_cTipos,_cGrpProd)

Local _aArea := FWGetArea()
Local _aRet  :={0,0,0}
Local _cQuery:= ""
Local _cAlias:= GetNextAlias()

_cQuery := " SELECT ZZX.ZZX_CODPRD ,"
_cQuery += "        SUM(ZLX_VOLREC) ZLX_VOLREC, "
_cQuery += "        SUM(ZLX_TVLFRT) ZLX_TVLFRT, "
_cQuery += "        SUM(ZLX_ICMSFR) ZLX_ICMSFR"
_cQuery += " FROM  "+ RETSQLNAME('ZLX') +" ZLX, "
_cQuery +=            RETSQLNAME('ZZX') +" ZZX "
_cQuery += " WHERE "+ RETSQLDEL( 'ZLX,ZZX' )
_cQuery += "   AND ZLX.ZLX_CODANA = ZZX.ZZX_CODIGO "
_cQuery += "   AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL "
_cQuery += "   AND ZLX.ZLX_PGFRT  = 'S' "
_cQuery += "   AND ZLX.ZLX_FILIAL IN "+FormatIn(AllTrim(_cFiliais),";") 
_cQuery += "   AND ZLX.ZLX_DTENTR BETWEEN '" + DToS(MV_PAR05) + "' AND '"+ DToS(MV_PAR06) +"' "
_cQuery += "   AND ZLX.ZLX_TIPOLT IN " + FormatIn(AllTrim(_cTipos),";")//F=LEITE FILIAIS //T=LEITE TERCEIRO //P=PLATAFORMA
_cQuery += "   AND ZZX.ZZX_CODPRD = '"+ _cGrpProd+"' "  // PRODUTOS:  //001 - LEITE IN-NATURA //002 - SORO LIQUIDO //003 - SORO CONCENTRADO //004 - CREME       
_cQuery += " GROUP BY ZZX_CODPRD"

MPSysOpenQuery( _cQuery , _cAlias ) 

While (_cAlias)->( !Eof() )
	_aRet[01] += (_cAlias)->ZLX_VOLREC                          //Volume Recebido
	If MV_PAR13 = 2 //NAO
	   _aRet[02] += (_cAlias)->ZLX_TVLFRT//Total do Frete C/ ICMS
	Else
	   _aRet[02] += ((_cAlias)->ZLX_TVLFRT - (_cAlias)->ZLX_ICMSFR)//Total do Frete S/ ICMS
    EndIf	
	_aRet[03] += (_cAlias)->ZLX_ICMSFR                          //Total ICMS
							
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_aRet)

/*
==================================================================================================================================================
Programa----------: CusComICMS
Autor-------------: Alex Wallauer
Data da Criacao---: 30/08/2018
Descrição---------: Baseado no Relatório dos registros de recebimentos de leite de terceiros - Síntese de Recepções - RGLT033
Parametros--------: _cFilis,_cGrpProd: 001-LEITE IN-NATURA, 002-SORO LIQUIDO, 003-SORO CONCENTRADO, 004-CREME, 011-SORO PRE-CONCENTRADO
Retorno-----------: _aRet: {Volume,Valor}
==================================================================================================================================================
*/
Static Function CusComICMS(_cFilis,_cGrpProd)

Local _aArea := FWGetArea()
Local _aRet  :={0,0}
Local _cQuery:= ""
Local _cAlias:= GetNextAlias()

_cQuery += " SELECT "
_cQuery += "     ZLX.ZLX_TIPOLT ,"
_cQuery += "     ZLX.ZLX_FILIAL ,"
_cQuery += "     SUM(ZLX.ZLX_VOLREC) ZLX_VOLREC ,"
_cQuery += "     Round( DECODE( ZZX.ZZX_CODPRD , '004' , 0 , SUM( ZLX.ZLX_VOLREC * SC7.C7_PRECO ) ) + "
_cQuery += "     SUM((((NVL(Round((SELECT AVG(ZAP_GORD) "
_cQuery +=                        " FROM  "+ RETSQLNAME('ZAP') +" ZAP "
_cQuery +=                        " WHERE "+ RETSQLDEL('ZAP')
_cQuery +=                        " AND ZLX.ZLX_FILIAL = ZAP.ZAP_FILIAL "
_cQuery +=                        " AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO ) , 2 ) , 0 ) - SC7.C7_L_PMGB ) * ZLX.ZLX_VOLREC ) / 100 ) "
_cQuery +=                        "    * SC7.C7_L_EXEMG ) , 2 ) VL_A_PAGAR "
_cQuery += " FROM "
_cQuery += RETSQLNAME('ZLX') +" ZLX, "
_cQuery += RETSQLNAME('SD1') +" SD1, "
_cQuery += RETSQLNAME('SC7') +" SC7, "
_cQuery += RETSQLNAME('ZZX') +" ZZX  "
_cQuery += " WHERE "+ RETSQLDEL( 'ZLX,SD1,SC7,ZZX' )
_cQuery += " AND ZLX.ZLX_FILIAL = SC7.C7_FILIAL"
_cQuery += " AND SD1.D1_PEDIDO  = SC7.C7_NUM"
_cQuery += " AND SD1.D1_ITEMPC  = SC7.C7_ITEM"
_cQuery += " AND ZLX.ZLX_NRONF  = SD1.D1_DOC"
_cQuery += " AND ZLX.ZLX_SERINF = SD1.D1_SERIE"
_cQuery += " AND ZLX.ZLX_FORNEC = SD1.D1_FORNECE"
_cQuery += " AND ZLX.ZLX_LJFORN = SD1.D1_LOJA"
_cQuery += " AND ZLX.ZLX_FILIAL = SD1.D1_FILIAL"
_cQuery += " AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA"
_cQuery += " AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL"
_cQuery += " AND SD1.D1_FORMUL  <> 'S'"
_cQuery += " AND ZLX.ZLX_TIPOLT <> 'P'"//"Terceiros" //F=LEITE FILIAIS //T=LEITE TERCEIRO //P=PLATAFORMA(LEITE PRATAFORMA)
_cQuery += " AND ZLX.ZLX_FILIAL IN "+ FormatIn( _cFilis , ';' )
_cQuery += " AND ZLX.ZLX_DTENTR BETWEEN '" + DToS(MV_PAR05) + "' AND '"+ DToS(MV_PAR06) +"' "//Data Inicial e final
If !_cGrpProd $ "004/011"
   _cQuery += " AND ZZX.ZZX_FORNEC <> 'F00001' "//"Terceiros"
EndIf
_cQuery += " AND SubStr(ZZX.ZZX_FORNEC,1,1) <> 'Z' "//"Terceiros"
_cQuery += " AND ZZX.ZZX_CODPRD = '"+ _cGrpProd+"' "// PRODUTOS:  //001 - LEITE IN-NATURA //002 - SORO LIQUIDO //003 - SORO CONCENTRADO //004 - CREME //011 SORO PRE-CONCENTRADO
_cQuery += " GROUP BY ZZX_CODPRD, ZLX.ZLX_TIPOLT, ZLX.ZLX_FILIAL"

nHandle := FCreate(_cdir+"MEST009_CusComICMS_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cQuery)
FClose(nHandle)

MPSysOpenQuery( _cQuery , _cAlias ) 

While (_cAlias)->( !Eof() )
   _aRet[01] += (_cAlias)->ZLX_VOLREC
   _aRet[02] += (_cAlias)->VL_A_PAGAR
	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

Return(_aRet)

/*
===============================================================================================================================
Programa----------: CusMGCMS
Autor-------------: Alex Wallauer
Data da Criacao---: 30/08/2018
Descrição---------: Baseado no Relatório dos registros de recebimentos de leite de terceiros - Síntese de Recepções - RGLT033
Parametros--------: _cFilis,
Retorno-----------: _aRet: {Volume,Valor}
===============================================================================================================================
*/
Static Function CusMGCMS(_cFilis)

Local _aArea := FWGetArea()
Local _aRet  :={},X:=0
Local _cQuery:= ""
Local _cAlias:= GetNextAlias()
Local _cDtini:= DToS(MV_PAR05) 
Local _cDtfim:= DToS(MV_PAR06) 

If Len(_aSalvaCusMGCMS) > 0
   Return _aSalvaCusMGCMS
EndIf

_cQuery += " SELECT "
_cQuery +=     " RES.ZZX_CODPRD,"
_cQuery +=     " RES.ZLX_TIPOLT,"
_cQuery +=     " NVL(Round(SUM(((( RES.MED_GOR - RES.C7_L_PMGB )* RES.ZLX_VOLREC )/100)),4),0) QTD_EMGKG, "
_cQuery +=     " NVL(Round(SUM(((( RES.MED_GOR - RES.C7_L_PMGB )* RES.ZLX_VOLREC )/100)*RES. C7_L_EXEMG ),2),0) VLR_PGMG, "
_cQuery +=     " NVL(SUM(RES.ZLX_ICMSNF)  ,0) ZLX_ICMSNF ," //Result.Cr. ICMS
_cQuery +=     " NVL(AVG(RES.VL_ICMS_NF_C),0) VLR_ICMSC  ," //Cr. ICMS NFC
_cQuery +=     " NVL(AVG(RES.VL_ICMS_NF_D),0) VLR_ICMSD   " //Déb. ICMS NFD
_cQuery += " FROM (SELECT "
_cQuery +=             " ZZX.ZZX_CODPRD,"
_cQuery +=             " ZLX.ZLX_TIPOLT,"
_cQuery +=             " ZLX.ZLX_FORNEC,"
_cQuery +=             " ZLX.ZLX_LJFORN,"
_cQuery +=             " ZLX.ZLX_CODANA,"
_cQuery +=             " SC7.C7_L_EXEMG,"
_cQuery +=             " SC7.C7_L_PMGB,"
_cQuery +=             " SC7.C7_PRECO, "
_cQuery +=             " SUM(ZLX.ZLX_VOLREC) ZLX_VOLREC,"
_cQuery +=             " SUM(ZLX.ZLX_ICMSNF) ZLX_ICMSNF," //
_cQuery +=             " Round(AVG(NVL((SELECT AVG(ZAP_GORD) "
_cQuery +=                              " FROM "+ RETSQLNAME("ZAP") +" ZAP "
_cQuery +=                             " WHERE ZAP.D_E_L_E_T_ = ' ' "
_cQuery +=                               " AND ZLX.ZLX_FILIAL = ZAP.ZAP_FILIAL "
_cQuery +=                               " AND ZLX.ZLX_CODANA = ZAP.ZAP_CODIGO),0)),2) MED_GOR,"//
_cQuery +=             " NVL(( SELECT SUM( SD1CI.D1_VALICM ) "
_cQuery +=                     " FROM "+ RetSqlName('SD1') +" SD1CI "
_cQuery +=                    " WHERE SD1CI.D_E_L_E_T_ = ' ' "
_cQuery +=                      " AND SD1CI.D1_TIPO IN ('N','C') "
_cQuery +=                      " AND SD1CI.D1_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' )
_cQuery +=                      " AND EXISTS (SELECT 1 "
_cQuery +=                                    " FROM "+ RetSqlName('ZLX') +" ZLXCI, "+ RetSqlName('ZZX') +" ZZXCI, "+ RetSqlName('SC7') +" SC7CI, "+ RetSqlName('SD1') +" SD1CCI "
_cQuery +=                                   " WHERE ZLXCI.D_E_L_E_T_ = ' ' "
_cQuery +=                                     " AND ZZXCI.D_E_L_E_T_ = ' ' "
_cQuery +=                                     " AND SC7CI.D_E_L_E_T_ = ' ' "
_cQuery +=                                     " AND SD1CCI.D_E_L_E_T_ = ' ' "
_cQuery +=                                     " AND ZLXCI.ZLX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND ZZXCI.ZZX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND SC7CI.C7_FILIAL IN "+  FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND SD1CCI.D1_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND ZLXCI.ZLX_FILIAL = ZZXCI.ZZX_FILIAL"
_cQuery +=                                     " AND ZZXCI.ZZX_FILIAL = SC7CI.C7_FILIAL"
_cQuery +=                                     " AND SC7CI.C7_FILIAL = SD1CCI.D1_FILIAL"
_cQuery +=                                     " AND SD1CI.D1_FILIAL = SD1CCI.D1_FILIAL"
_cQuery +=                                     " AND SD1CI.D1_FORNECE = ZLXCI.ZLX_FORNEC "
_cQuery +=                                     " AND SD1CI.D1_LOJA = ZLXCI.ZLX_LJFORN "
_cQuery +=                                     " AND SD1CI.D1_NFORI = ZLXCI.ZLX_NRONF "
_cQuery +=                                     " AND SD1CI.D1_SERIORI = ZLXCI.ZLX_SERINF "
_cQuery +=                                     " AND SD1CI.D1_FORNECE = SD1CCI.D1_FORNECE "
_cQuery +=                                     " AND SD1CI.D1_LOJA = SD1CCI.D1_LOJA "
_cQuery +=                                     " AND SD1CI.D1_NFORI = SD1CCI.D1_DOC "
_cQuery +=                                     " AND SD1CI.D1_SERIORI = SD1CCI.D1_SERIE "
_cQuery +=                                     " AND ZLXCI.ZLX_DTENTR BETWEEN '"+ _cDtini +"' AND '"+ _cDtfim +"' "
_cQuery +=                                     " AND SD1CI.D1_FORNECE = ZLX.ZLX_FORNEC "
_cQuery +=                                     " AND SD1CI.D1_LOJA = ZLX.ZLX_LJFORN "
_cQuery +=                                     " AND ZZXCI.ZZX_CODIGO = ZLXCI.ZLX_CODANA "
_cQuery +=                                     " AND ZZXCI.ZZX_CODPRD = ZZX_CODPRD "
_cQuery +=                                     " AND SC7CI.C7_L_EXEMG = SC7.C7_L_EXEMG "
_cQuery +=                                     " AND SC7CI.C7_L_PMGB = SC7.C7_L_PMGB "
_cQuery +=                                     " AND SC7CI.C7_PRECO = SC7.C7_PRECO "
_cQuery +=                                     " AND SD1CCI.D1_PEDIDO = SC7CI.C7_NUM "
_cQuery +=                                     " AND SD1CCI.D1_ITEMPC = SC7CI.C7_ITEM)),0) VL_ICMS_NF_C,"  //
_cQuery +=             " NVL(( SELECT SUM(SD2DI.D2_VALICM) "
_cQuery +=                     " FROM "+ RetSqlName('SD2') +" SD2DI "
_cQuery +=                    " WHERE SD2DI.D_E_L_E_T_ = ' ' "
_cQuery +=                      " AND SD2DI.D2_TIPO IN ('B','D') "
_cQuery +=                      " AND SD2DI.D2_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' )
_cQuery +=                      " AND EXISTS (SELECT 1 "
_cQuery +=                                    " FROM "+ RetSqlName('ZLX') +" ZLXDI, "+ RetSqlName('ZZX') +" ZZXDI, "+ RetSqlName('SC7') +" SC7DI, "+ RetSqlName('SD1') +" SD1DDI "
_cQuery +=                                   " WHERE ZLXDI.D_E_L_E_T_  = ' ' "
_cQuery +=                                     " AND ZZXDI.D_E_L_E_T_  = ' ' "
_cQuery +=                                     " AND SC7DI.D_E_L_E_T_  = ' ' "
_cQuery +=                                     " AND SD1DDI.D_E_L_E_T_ = ' ' "
_cQuery +=                                     " AND ZLXDI.ZLX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND ZZXDI.ZZX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND SC7DI.C7_FILIAL IN "+  FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND SD1DDI.D1_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=                                     " AND ZLXDI.ZLX_FILIAL = ZZXDI.ZZX_FILIAL"
_cQuery +=                                     " AND ZZXDI.ZZX_FILIAL = SC7DI.C7_FILIAL"
_cQuery +=                                     " AND SC7DI.C7_FILIAL = SD1DDI.D1_FILIAL"
_cQuery +=                                     " AND SD2DI.D2_FILIAL = SD1DDI.D1_FILIAL"
_cQuery +=                                     " AND SD2DI.D2_CLIENTE = ZLXDI.ZLX_FORNEC "
_cQuery +=                                     " AND SD2DI.D2_LOJA = ZLXDI.ZLX_LJFORN "
_cQuery +=                                     " AND SD2DI.D2_NFORI = ZLXDI.ZLX_NRONF "
_cQuery +=                                     " AND SD2DI.D2_SERIORI = ZLXDI.ZLX_SERINF "
_cQuery +=                                     " AND SD2DI.D2_CLIENTE = SD1DDI.D1_FORNECE "
_cQuery +=                                     " AND SD2DI.D2_LOJA = SD1DDI.D1_LOJA "
_cQuery +=                                     " AND SD2DI.D2_NFORI = SD1DDI.D1_DOC "
_cQuery +=                                     " AND SD2DI.D2_SERIORI = SD1DDI.D1_SERIE "
_cQuery +=                                     " AND ZLXDI.ZLX_DTENTR BETWEEN '"+ _cDtini +"' AND '"+ _cDtfim +"' "
_cQuery +=                                     " AND SD2DI.D2_CLIENTE = ZLX.ZLX_FORNEC "
_cQuery +=                                     " AND SD2DI.D2_LOJA = ZLX.ZLX_LJFORN "
_cQuery +=                                     " AND ZZXDI.ZZX_CODIGO = ZLXDI.ZLX_CODANA "
_cQuery +=                                     " AND ZZXDI.ZZX_CODPRD = ZZX_CODPRD "
_cQuery +=                                     " AND SC7DI.C7_L_EXEMG = SC7.C7_L_EXEMG "
_cQuery +=                                     " AND SC7DI.C7_L_PMGB = SC7.C7_L_PMGB "
_cQuery +=                                     " AND SC7DI.C7_PRECO = SC7.C7_PRECO "
_cQuery +=                                     " AND SD1DDI.D1_PEDIDO = SC7DI.C7_NUM "
_cQuery +=                                     " AND SD1DDI.D1_ITEMPC = SC7DI.C7_ITEM)),0) VL_ICMS_NF_D "//,"
_cQuery +=         " FROM "+ RETSQLNAME("ZLX") +" ZLX, "+RETSQLNAME("ZZX") +" ZZX, "
_cQuery +=                   RETSQLNAME("ZZV") +" ZZV, "+RETSQLNAME("SC7") +" SC7 ,"+ RETSQLNAME("SD1") +" SD1 "
_cQuery +=         " WHERE ZLX.D_E_L_E_T_ = ' ' "
_cQuery +=           " AND ZZX.D_E_L_E_T_ = ' ' "
_cQuery +=           " AND ZZV.D_E_L_E_T_ = ' ' "
_cQuery +=           " AND SC7.D_E_L_E_T_ = ' ' "
_cQuery +=           " AND SD1.D_E_L_E_T_ = ' ' "
_cQuery +=           " AND ZLX.ZLX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=           " AND ZZX.ZZX_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=           " AND ZZV.ZZV_FILIAL IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=           " AND SC7.C7_FILIAL  IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=           " AND SD1.D1_FILIAL  IN "+ FormatIn( AllTrim( _cFilis ) , ';' ) 
_cQuery +=           " AND ZLX.ZLX_FILIAL = ZZX.ZZX_FILIAL"
_cQuery +=           " AND ZZX.ZZX_FILIAL = ZZV.ZZV_FILIAL"
_cQuery +=           " AND ZZV.ZZV_FILIAL = SC7.C7_FILIAL"
_cQuery +=           " AND SC7.C7_FILIAL = SD1.D1_FILIAL"
_cQuery +=           " AND ZZX.ZZX_CODIGO = ZLX.ZLX_CODANA "
_cQuery +=           " AND ZZX.ZZX_PLACA = ZZV.ZZV_PLACA "
_cQuery +=           " AND ZZV.ZZV_TRANSP = ZLX.ZLX_TRANSP "
_cQuery +=           " AND ZZV.ZZV_LJTRAN = ZLX.ZLX_LJTRAN "
_cQuery +=           " AND SD1.D1_PEDIDO = SC7.C7_NUM "
_cQuery +=           " AND SD1.D1_ITEMPC = SC7.C7_ITEM "
_cQuery +=           " AND ZLX.ZLX_NRONF = SD1.D1_DOC "
_cQuery +=           " AND ZLX.ZLX_SERINF = SD1.D1_SERIE "
_cQuery +=           " AND ZLX.ZLX_FORNEC = SD1.D1_FORNECE "
_cQuery +=           " AND ZLX.ZLX_LJFORN = SD1.D1_LOJA "
_cQuery +=           " AND SD1.D1_FORMUL <> 'S' "
_cQuery +=           " AND ZLX.ZLX_TIPOLT = 'T' "
_cQuery +=           " AND ZLX.ZLX_DTENTR BETWEEN '"+ _cDtini +"' AND '"+ _cDtfim +"' "
_cQuery +="      GROUP BY ZZX.ZZX_CODPRD,ZLX.ZLX_TIPOLT,ZLX.ZLX_FORNEC,ZLX.ZLX_LJFORN,ZLX.ZLX_CODANA,SC7.C7_L_EXEMG,SC7.C7_L_PMGB,SC7.C7_PRECO) RES "//*RES*
_cQuery +="GROUP BY RES.ZZX_CODPRD, RES.ZLX_TIPOLT 

nHandle := FCreate(_cdir+"QUERY_G_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cQuery)
FClose(nHandle)

aAdd(_aRet,{0,0,0})//"001"
aAdd(_aRet,{X,X,0})//"002"// X posiçoes que podem vir a ser usadas
aAdd(_aRet,{X,X,0})//"003"// X posiçoes que podem vir a ser usadas
aAdd(_aRet,{X,X,0})//"004"// X posiçoes que podem vir a ser usadas

If MV_PAR13 = 2 //NÃO
   Return(_aRet)
EndIf

MPSysOpenQuery( _cQuery , _cAlias ) 

While (_cAlias)->( !Eof() )
   If (_cAlias)->ZZX_CODPRD = "001"    //001 - LEITE IN-NATURA
      _aRet[1,1] += (_cAlias)->QTD_EMGKG
      _aRet[1,2] += (_cAlias)->VLR_PGMG
      _aRet[1,3] +=((_cAlias)->ZLX_ICMSNF + (_cAlias)->VLR_ICMSC - (_cAlias)->VLR_ICMSD)
   ElseIf (_cAlias)->ZZX_CODPRD = "002"//002 - SORO LIQUIDO
      _aRet[2,3] +=((_cAlias)->ZLX_ICMSNF + (_cAlias)->VLR_ICMSC - (_cAlias)->VLR_ICMSD)
   ElseIf (_cAlias)->ZZX_CODPRD = "003"//003 - SORO CONCENTRADO
      _aRet[3,3] +=((_cAlias)->ZLX_ICMSNF + (_cAlias)->VLR_ICMSC - (_cAlias)->VLR_ICMSD)
   ElseIf (_cAlias)->ZZX_CODPRD = "004"//004 - CREME
      _aRet[4,3] +=((_cAlias)->ZLX_ICMSNF + (_cAlias)->VLR_ICMSC - (_cAlias)->VLR_ICMSD)
   EndIf   

	(_cAlias)->( DBSkip() )
EndDo

(_cAlias)->( DBCloseArea() )

FWRestArea(_aArea)

_aSalvaCusMGCMS:=_aRet

Return(_aRet)

/*
===============================================================================================================================
Programa----------: MEST9ICMS
Autor-------------: Alex Walaluer
Data da Criacao---: 02/04/2019
Descricao---------: Retorna valores de cada ICMS e carga nas variaveis Private 
Parametros--------: Tipo do ICMS,_cChave
Retorno-----------: VALORES DO PREÇO MEDIO de cada ICMS
===============================================================================================================================
*/
Static Function MEST9ICMS(cTipoICMS,_cChave,_cFilis)

Local _cQuery1   := ""
Local _cQuery2   := ""
Local _cQuery3   := ""
Local _caRIcmEst := ""
Local _caRIcmInt := ""
Local _caRIcmTrs := ""
Local _cGrpCus   := ""
Local _cEstFilAnt:= ""
Local _nValor    := _nQtde := 0 , I
Local _lAtivaLOG := .F.

If cTipoICMS == "CARGA_VARIAVEIS_ICMS"
	_nVlrIcm :=_nVIcmEst:=_nVIcmInt:=_nVIcmTrs:=_nDifAlq:=0//Variaveis antigas
    _nICMSEst:=_nICMSInt:=_nICMSTrs:=0//Variaveis novas valores preco medio
    nDespEst := nOprsEst:=0//Variaveis novas para calcular o percentual
    nDespInt := nOprsInt:=0//Variaveis novas para calcular o percentual
    nDespTrs := nOprsTrs:=0//Variaveis novas para calcular o percentual

    _cProduto := AllTrim(Posicione("ZL6",8,_cChave,"ZL6_CODPRO"))//TEM QUE SER Private PQ É UMA FUNÇÃO MEST9ICMS() RECURSIVA
	_caRIcmEst:= AllTrim(Posicione("ZL6",8,_cChave,"ZL6_REGICE"))
	_caRIcmInt:= AllTrim(Posicione("ZL6",8,_cChave,"ZL6_REGICI"))
	_caRIcmTrs:= AllTrim(Posicione("ZL6",8,_cChave,"ZL6_REGICT"))
    _cSegUni  := AllTrim(Posicione("ZL6",8,_cChave,"ZL6_TUNID" ))

    _nDifAlq  := MEST9ICMS("DIFERENCIAL",_cChave)

    _cValores:=_caRIcmEst+CRLF
    _cValores+=_caRIcmInt+CRLF
    _cValores+=_caRIcmTrs+CRLF

    If Empty(_caRIcmEst)
	   _nVIcmEst:= Posicione("ZL6",8,_cChave,"ZL6_VICMSE")//valor do jeito antigo
	Else
	   _caRIcmEst:=StrTokArr(_caRIcmEst,";")
       _nICMSEst :=MEST9ICMS("ESTADUAL",_cChave)

       _dDtSeek:=StrZero(MONTH(MV_PAR05),2)+AllTrim(Str(YEAR(MV_PAR05)))
       For I := 1 To Len(_caRIcmEst)
           If ZM1->(DBSeek(xFilial()+_dDtSeek+_caRIcmEst[I] ))
              nDespEst += ZM1->ZM1_DESP
   	          nOprsEst +=(ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD)
	       EndIf   
           _cValores+=_dDtSeek+" "+_caRIcmEst[I]+" D: "+Str(ZM1->ZM1_DESP,22,7)+CHR(13)+CHR(10)
           _cValores+=_dDtSeek+" "+_caRIcmEst[I]+" O: "+Str((ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD),22,7)+CHR(13)+CHR(10)
       Next
       _cValores+=_dDtSeek+" T. D.: "+Str((nDespEst),22,7)+CHR(13)+CHR(10)
       _cValores+=_dDtSeek+" T. O.: "+Str((nOprsEst),22,7)+CHR(13)+CHR(10)

       If  nDespEst > 0
	      _nVIcmEst:=(nDespEst/nOprsEst)*_nICMSEst//Falta multiplicar pela quantidade
	   EndIf   

	EndIf   

    If Empty(_caRIcmInt)
	   _nVIcmInt:= Posicione("ZL6",8,_cChave,"ZL6_VICMSI")//valor do jeito antigo
	Else
	   _nVIcmInt :=0
	   _caRIcmInt:=StrTokArr(_caRIcmInt,";") 
       _nICMSInt :=MEST9ICMS("INTERESTADUAL",_cChave)

       _dDtSeek:=StrZero(MONTH(MV_PAR05),2)+AllTrim(Str(YEAR(MV_PAR05)))
       For I := 1 To Len(_caRIcmInt)
           If ZM1->(DBSeek(xFilial()+_dDtSeek+_caRIcmInt[I] ))
              nDespInt += ZM1->ZM1_DESP
	          nOprsInt +=(ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD)
	       EndIf   
           _cValores+=_dDtSeek+" "+_caRIcmInt[I]+" D: "+Str(ZM1->ZM1_DESP,22,7)+CHR(13)+CHR(10)
           _cValores+=_dDtSeek+" "+_caRIcmInt[I]+" O: "+Str((ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD),22,7)+CHR(13)+CHR(10)
       Next
       _cValores+=_dDtSeek+" T. D.: "+Str((nDespInt),22,7)+CHR(13)+CHR(10)
       _cValores+=_dDtSeek+" T. O.: "+Str((nOprsInt),22,7)+CHR(13)+CHR(10)

       If nDespInt > 0
	      _nVIcmInt :=(nDespInt/nOprsInt)*_nICMSInt//Falta multiplicar pela quantidade
       EndIf
	EndIf   

    If Empty(_caRIcmTrs)
	   _nVIcmTrs:= Posicione("ZL6",8,_cChave,"ZL6_VICMST")//valor do jeito antigo
	Else
	   _nVIcmTrs :=0
	   _caRIcmTrs:=StrTokArr(_caRIcmTrs,";")
       _nICMSTrs :=MEST9ICMS("TRANSFERENCIA",_cChave)

       _dDtSeek:=StrZero(MONTH(MV_PAR05),2)+AllTrim(Str(YEAR(MV_PAR05)))
        For I := 1 To Len(_caRIcmTrs)
            If ZM1->(DBSeek(xFilial()+_dDtSeek+_caRIcmTrs[I] ))
               nDespTrs += ZM1->ZM1_DESP
	           nOprsTrs +=(ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD)
	        EndIf   
            _cValores+=_dDtSeek+" "+_caRIcmTrs[I]+" D: "+Str(ZM1->ZM1_DESP,22,7)+CHR(13)+CHR(10)
            _cValores+=_dDtSeek+" "+_caRIcmTrs[I]+" O: "+Str((ZM1->ZM1_VLROP - ZM1->ZM1_VLROPD),22,7)+CHR(13)+CHR(10)
        Next
        _cValores+=_dDtSeek+" T. D.: "+Str((nDespTrs),22,7)+CHR(13)+CHR(10)
        _cValores+=_dDtSeek+" T. O.: "+Str((nOprsTrs),22,7)+CHR(13)+CHR(10)

       If nDespTrs > 0
	      _nVIcmTrs :=(nDespTrs/nOprsTrs)*_nICMSTrs//Falta multiplicar pela quantidade
	   EndIf
	EndIf   

    If _lAtivaLOG
       nHandle := FCreate(_cdir+"VAL_ICMS_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
       FWrite(nHandle, _cValores )
       FClose(nHandle)
	EndIf   
    
    Return 0 //RETORNO DO "CARGA_VARIAVEIS_ICMS"

ElseIf cTipoICMS == "ESTADUAL"
   //Preço médio Estadual (quant e valor)
   //Select Vendas:
   _cEstFilAnt:= Posicione("ZZM",1,xFilial("ZZM")+cFilAnt,"ZZM_EST")

   _cQuery1 := " SELECT SUM(D2_TOTAL) AS VLR, "
   If _cSegUni = "S"
      _cQuery1 += " SUM(D2_QTSEGUM) as QTD "
   Else
      _cQuery1 += " SUM(D2_QUANT) as QTD "
   EndIf
   _cQuery1 += " FROM "+ RETSQLNAME("SD2")+" SD2 "  
   _cQuery1 += " JOIN  "+RETSQLNAME("ZAY")+" ZAY ON D2_CF = ZAY_CF "
   _cQuery1 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND ZAY.D_E_L_E_T_ = ' ' "
   _cQuery1 += "    AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
   _cQuery1 += "    AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
   _cQuery1 += "    AND ZAY_TPOPER = 'V' AND  D2_EST = '"+_cEstFilAnt+"' "
   _cQuery1 += "    AND D2_TP = 'PA'" 
   If !Empty(_cProduto)
      _cQuery1 += " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
   EndIf   
   If !Empty(_cGrpCus)
      _cQuery1 += " AND SD2.D2_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
   EndIf   

//	+ 
//	Select Bonificações
   _cQuery2 := " SELECT 0 AS VLR, "
   If _cSegUni = "S"
      _cQuery2 += " SUM(D2_QTSEGUM) as QTD "
   Else
      _cQuery2 += " SUM(D2_QUANT) as QTD "
   EndIf
   _cQuery2 += " FROM "+ RETSQLNAME("SD2")+" SD2 "  
   _cQuery2 += " JOIN  "+RETSQLNAME("ZAY")+" ZAY ON D2_CF = ZAY_CF "
   _cQuery2 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND ZAY.D_E_L_E_T_ = ' ' "
   _cQuery2 += "    AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
   _cQuery2 += "    AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
   _cQuery2 += "    AND ZAY_TPOPER = 'B' AND  D2_EST = '"+_cEstFilAnt+"' "
   _cQuery2 += "    AND D2_TP = 'PA'" 
   If !Empty(_cProduto)
      _cQuery2 += " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
   EndIf   
   If !Empty(_cGrpCus)
      _cQuery2 += " AND SD2.D2_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
   EndIf   

//	(-)
//	Select Devoluções
	_cQuery3:="SELECT SUM(D1_TOTAL) AS VLR, "
    If _cSegUni = "S"
       _cQuery3 += " SUM(D1_QTSEGUM) as QTD "
    Else
       _cQuery3 += " SUM(D1_QUANT) as QTD "
    EndIf
	_cQuery3+="       FROM "+RETSQLNAME("SD1")+" SD1"
	_cQuery3+="       JOIN "+RETSQLNAME("SF1")+" SF1 ON D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "  
	_cQuery3+=" WHERE SD1.D1_FILIAL = '"+cFilAnt+"'"
	_cQuery3+="   AND SD1.D1_DTDIGIT BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery3+="   AND SD1.D1_TP = 'PA' AND D1_TIPO = 'D' AND D1_FORMUL = 'S' " 
	_cQuery3+="   AND SF1.F1_EST = '"+_cEstFilAnt+"' "
	_cQuery3+="   AND SD1.D_E_L_E_T_ = ' ' AND  SF1.D_E_L_E_T_ = ' ' "
	_cQuery3+="   AND SD1.D1_CF NOT IN ('1208','1209','2208','2209') "
    If !Empty(_cProduto)
        _cQuery3 += " AND SD1.D1_COD IN " + FormatIn(AllTrim(_cproduto),";")
     EndIf   
     If !Empty(_cGrpCus)
        _cQuery3 += " AND SD1.D1_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
     EndIf   
//	=
//	Resultado = soma(VLR) / soma(QTD) 
ElseIf cTipoICMS == "INTERESTADUAL"
   //Preço médio Estadual (quant e valor)
   //Select Vendas:
   _cEstFilAnt:= Posicione("ZZM",1,xFilial("ZZM")+cFilAnt,"ZZM_EST")

   _cQuery1 := " SELECT SUM(D2_TOTAL) AS VLR,  "
   If _cSegUni = "S"
      _cQuery1 += " SUM(D2_QTSEGUM) as QTD "
   Else
      _cQuery1 += " SUM(D2_QUANT) as QTD "
   EndIf
   _cQuery1 += " FROM "+ RETSQLNAME("SD2")+" SD2 "  
   _cQuery1 += " JOIN  "+RETSQLNAME("ZAY")+" ZAY ON D2_CF = ZAY_CF "
   _cQuery1 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND ZAY.D_E_L_E_T_ = ' ' "
   _cQuery1 += "    AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
   _cQuery1 += "    AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
   _cQuery1 += "    AND ZAY_TPOPER = 'V' AND  D2_EST <> '"+_cEstFilAnt+"' "
   _cQuery1 += "    AND D2_TP = 'PA'" 
   If !Empty(_cProduto)
      _cQuery1 += " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
   EndIf   
   If !Empty(_cGrpCus)
      _cQuery1 += " AND SD2.D2_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
   EndIf   

//	+ 
//	Select Bonificações
   _cQuery2 := " SELECT 0 AS VLR, "
   If _cSegUni = "S"
      _cQuery2 += " SUM(D2_QTSEGUM) as QTD "
   Else
      _cQuery2 += " SUM(D2_QUANT) as QTD "
   EndIf
   _cQuery2 += " FROM "+ RETSQLNAME("SD2")+" SD2 "  
   _cQuery2 += " JOIN  "+RETSQLNAME("ZAY")+" ZAY ON D2_CF = ZAY_CF "
   _cQuery2 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND ZAY.D_E_L_E_T_ = ' ' "
   _cQuery2 += "    AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
   _cQuery2 += "    AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
   _cQuery2 += "    AND ZAY_TPOPER = 'B' AND  D2_EST <> '"+_cEstFilAnt+"' "
   _cQuery2 += "    AND D2_TP = 'PA'" 
   If !Empty(_cProduto)
      _cQuery2 += " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
   EndIf   
   If !Empty(_cGrpCus)
      _cQuery2 += " AND SD2.D2_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
   EndIf   

//	(-)
//	Select Devoluções
	_cQuery3:="SELECT SUM(D1_TOTAL) AS VLR, "
    If _cSegUni = "S"
       _cQuery3 += " SUM(D1_QTSEGUM) as QTD "
    Else
       _cQuery3 += " SUM(D1_QUANT) as QTD "
    EndIf
	_cQuery3+="       FROM "+RETSQLNAME("SD1")+" SD1"
	_cQuery3+="       JOIN "+RETSQLNAME("SF1")+" SF1 ON D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "  
	_cQuery3+=" WHERE SD1.D1_FILIAL = '"+cFilAnt+"'"
	_cQuery3+="   AND SD1.D1_DTDIGIT BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery3+="   AND SD1.D1_TP = 'PA' AND D1_TIPO = 'D' AND D1_FORMUL = 'S' " 
	_cQuery3+="   AND SF1.F1_EST <> '"+_cEstFilAnt+"' "
	_cQuery3+="   AND SD1.D_E_L_E_T_ = ' ' AND  SF1.D_E_L_E_T_ = ' ' "
	_cQuery3+="   AND SD1.D1_CF NOT IN ('1208','1209','2208','2209') "
    If !Empty(_cProduto)
        _cQuery3 += " AND SD1.D1_COD IN " + FormatIn(AllTrim(_cproduto),";")
     EndIf   
     If !Empty(_cGrpCus)
        _cQuery3 += " AND SD1.D1_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
     EndIf   
//	=
//	Resultado = soma(VLR) / soma(QTD) 
ElseIf cTipoICMS == "TRANSFERENCIA"
	//Preço médio Transferencia
	//	select saídas:
	_cQuery1 := " SELECT SUM(D2_TOTAL) AS VLR,  "
    If _cSegUni = "S"
       _cQuery1 += " SUM(D2_QTSEGUM) as QTD "
    Else
       _cQuery1 += " SUM(D2_QUANT) as QTD "
    EndIf
	_cQuery1 += " FROM "+ RETSQLNAME("SD2")+" SD2 "
	_cQuery1 += " JOIN  "+RETSQLNAME("ZAY")+" ZAY ON D2_CF = ZAY_CF "
	_cQuery1 += "  WHERE SD2.D_E_L_E_T_ = ' ' AND ZAY.D_E_L_E_T_ = ' ' "
	_cQuery1 += "    AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery1 += "    AND SD2.D2_FILIAL = '" + xFilial("SD2") + "'"
	_cQuery1 += "    AND ZAY_TPOPER = 'T' "
	_cQuery1 += "    AND D2_TP = 'PA'"
	If !Empty(_cProduto)
		_cQuery1 += " AND SD2.D2_COD IN " + FormatIn(AllTrim(_cproduto),";")
	EndIf
	If !Empty(_cGrpCus)
		_cQuery1 += " AND SD2.D2_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
	EndIf
	
	//	(-)
	//	Select Devoluções:
	_cQuery2:="SELECT SUM(D1_TOTAL) AS VLR, "
    If _cSegUni = "S"
       _cQuery2 += " SUM(D1_QTSEGUM) as QTD "
    Else
       _cQuery2 += " SUM(D1_QUANT) as QTD "
    EndIf
	_cQuery2+="       FROM "+RETSQLNAME("SD1")+" SD1"
	_cQuery2+="       JOIN "+RETSQLNAME("SF1")+" SF1 ON D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE AND D1_FORNECE = F1_FORNECE AND D1_LOJA = F1_LOJA "
	_cQuery2+=" WHERE SD1.D1_FILIAL = '"+cFilAnt+"'"
	_cQuery2+="   AND SD1.D1_DTDIGIT BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery2+="   AND SD1.D1_TP = 'PA' AND D1_TIPO = 'D' AND D1_FORMUL = 'S' "
	_cQuery2+="   AND SD1.D_E_L_E_T_ = ' ' AND  SF1.D_E_L_E_T_ = ' ' "
	_cQuery2+="   AND SD1.D1_CF IN ('1208','1209','2208','2209') "
	If !Empty(_cProduto)
		_cQuery2 += " AND SD1.D1_COD IN " + FormatIn(AllTrim(_cproduto),";")
	EndIf
	If !Empty(_cGrpCus)
		_cQuery2 += " AND SD1.D1_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
	EndIf
	//	=
	//	Resultado = soma(VLR) / soma(QTD)
	_cValores:=_cQuery1+CRLF+CRLF
	_cValores+=_cQuery2+CRLF+CRLF
	
    If _lAtivaLOG
	nHandle := FCreate(_cdir+"SELECT_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
	FWrite(nHandle, _cValores )
	FClose(nHandle)
	EndIf
	
	MPSysOpenQuery( _cQuery1 ,"Q1" )
	MPSysOpenQuery( _cQuery2 ,"Q2" )
	
	_cValores:=_cQuery1+CRLF+CRLF
	If .NOT. Q1->( Eof() )
		_nValor+=Q1->VLR
		_nQtde+=Q1->QTD
	EndIf
	_cValores+=Str(Q1->VLR,22,7)+CRLF
	_cValores+=Str(Q1->QTD,22,7)+CRLF+CRLF
	
	_cValores+=_cQuery2+CRLF+CRLF
	If .NOT. Q2->( Eof() )
		_nValor-=Q2->VLR
		_nQtde-=Q2->QTD
	EndIf
	_cValores+=Str(Q2->VLR,22,7)+CRLF
	_cValores+=Str(Q2->QTD,22,7)+CRLF+CRLF
	
	_cValores+=Str(_nValor,22,7)+CRLF
	_cValores+=Str(_nQtde,22,7)+CRLF
	
	_nValor:=(_nValor/_nQtde)
	
	_cValores+=Str(_nValor,22,7)+CRLF
	
    If _lAtivaLOG
		nHandle := FCreate(_cdir+"SELECT_VAL_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
		FWrite(nHandle, _cValores )
		FClose(nHandle)
	EndIf
	Q1->( DBCloseArea() )
	Q2->( DBCloseArea() )
	
	Return _nValor//RETORNO DO "TRANSFERENCIA"
ElseIf cTipoICMS == "DIFERENCIAL"
	_cQuery1:="SELECT SUM(D1_ICMSCOM) AS VLR  FROM "+RETSQLNAME("SD1")+" SD1"
	_cQuery1+=" WHERE SD1.D1_FILIAL = '"+cFilAnt+"'"
	_cQuery1+="   AND SD1.D_E_L_E_T_ = ' ' AND D1_ICMSCOM > 0 "
	_cQuery1+="   AND SD1.D1_DTDIGIT BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery1+="   AND SD1.D1_TP = 'PA' AND D1_TIPO = 'N'  " 
	_cQuery1+="   AND SD1.D1_CF IN ('1151','1152','2151','2152') "
    If !Empty(_cProduto)
        _cQuery1 += " AND SD1.D1_COD IN " + FormatIn(AllTrim(_cproduto),";")
     EndIf   
     If !Empty(_cGrpCus)
        _cQuery1 += " AND SD1.D1_GRUPO IN " + FormatIn(AllTrim(_cGrpCus),";")
     EndIf   

	MPSysOpenQuery( _cQuery1 ,"Q1" )
	
	_cValores:=_cQuery1+CRLF+CRLF
	If .NOT. Q1->( Eof() )
		_nValor:=Q1->VLR
	EndIf
	
	_cValores+=Str(_nValor,22,7)+CRLF
	
    If _lAtivaLOG
	nHandle := FCreate(_cdir+"SELECT_VAL_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
	FWrite(nHandle, _cValores )
	FClose(nHandle)
	EndIf
	Q1->( DBCloseArea() )

	Return _nValor//RETORNO DO "DIFERENCIAL"
ElseIf cTipoICMS == "FUNDOLEITE"// = FUNDOPEM
	_cQuery1:="SELECT SUM(E5_VALOR) AS VLR  FROM "+RETSQLNAME("SE5")+" SE5"
	_cQuery1+=" WHERE SE5.E5_FILIAL IN "+FormatIn(AllTrim(_cFilis),";") 
	_cQuery1+="   AND SE5.D_E_L_E_T_ = ' ' "
	_cQuery1+="   AND SE5.E5_DATA BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
	_cQuery1+="   AND SE5.E5_LA = 'S' AND E5_HISTOR LIKE '%FUNDOLEITE%'" //E5_CLIFOR = 'F02069' AND 

	MPSysOpenQuery( _cQuery1 ,"Q1" )
	
	_cValores:=_cQuery1+CRLF+CRLF
	If .NOT. Q1->( Eof() )
		_nValor:=Q1->VLR
	EndIf
	
	If Type("_nPerc") = "N"
	   _cValores+="_nPerc :"+Str(_nPerc,22,7)+CRLF
	EndIf   
	_cValores+=Str(_nValor,22,7)+CRLF
	
    If _lAtivaLOG
  	   nHandle := FCreate(_cdir+"SELECT_VAL_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
  	   FWrite(nHandle, _cValores )
  	   FClose(nHandle)
  	EndIf
	
	Q1->( DBCloseArea() )

	Return _nValor//RETORNO DO "DIFERENCIAL"
EndIf

_cValores:=_cQuery1+CRLF+CRLF
_cValores+=_cQuery2+CRLF+CRLF
_cValores+=_cQuery3+CRLF+CRLF

If _lAtivaLOG
  nHandle := FCreate(_cdir+"SELECT_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
  FWrite(nHandle, _cValores )
  FClose(nHandle)
EndIf

MPSysOpenQuery( _cQuery1 ,"Q1" ) 
MPSysOpenQuery( _cQuery2 ,"Q2" ) 
MPSysOpenQuery( _cQuery3 ,"Q3" ) 

_cValores:=_cQuery1+CRLF+CRLF
If .NOT. Q1->( Eof() )
   _nValor+=Q1->VLR
   _nQtde+=Q1->QTD
EndIf	
_cValores+=Str(Q1->VLR,22,7)+CRLF
_cValores+=Str(Q1->QTD,22,7)+CRLF+CRLF

_cValores+=_cQuery2+CRLF+CRLF
If .NOT. Q2->( Eof() )
   _nValor+=Q2->VLR
   _nQtde+=Q2->QTD
EndIf	     
_cValores+=Str(Q2->VLR,22,7)+CRLF
_cValores+=Str(Q2->QTD,22,7)+CRLF+CRLF

_cValores+=_cQuery3+CRLF+CRLF
If .NOT. Q3->( Eof() )
   _nValor-=Q3->VLR
   _nQtde-=Q3->QTD
EndIf	
_cValores+=Str(Q3->VLR,22,7)+CRLF
_cValores+=Str(Q3->QTD,22,7)+CRLF+CRLF

Q1->( DBCloseArea() )
Q2->( DBCloseArea() )
Q3->( DBCloseArea() )

_cValores+=Str(_nValor,22,7)+CRLF
_cValores+=Str(_nQtde,22,7)+CRLF
	
_nValor:=(_nValor/_nQtde)

_cValores+=Str(_nValor,22,7)+CRLF

If _lAtivaLOG
	nHandle := FCreate(_cdir+"SELECT_VAL_ICMS__"+cTipoICMS+"__"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
	FWrite(nHandle, _cValores )
	FClose(nHandle)
EndIf

Return _nValor//RETORNO DO "INTERESTADUAL" E "ESTADUAL"

/*
===============================================================================================================================
Programa----------: MEST9Rateio
Autor-------------: Alex Walaluer
Data da Criacao---: 02/04/2019
Descricao---------: Retorna Percentual de rateio que sera aplicado nas regras com Ratear Custo? = Sim
Parametros--------: Codigo do produto para buscar o percentual
Retorno-----------: Percentual de rateio
===============================================================================================================================
*/
Static Function MEST9Rateio(_CodProd)

Local _cQuery:= ""
Local nPos := 0

If (nPos:=aScan(_aProdsRateio , {|A| A[1] == _CodProd })) <> 0
	Return  _aProdsRateio[nPos,2]
EndIf

If !_CodProd $ ZL6->ZL6_PRDRAT
   Return 0
EndIf

_cQuery+= " SELECT D3_COD, SUM(D3_QUANT) * B1_PESO, Round(RATIO_TO_REPORT(SUM(D3_QUANT) * B1_PESO) OVER(),2)  PER_RAT "
_cQuery+= " FROM " + RetSqlName("SD3") + " SD3  JOIN " + RetSqlName("SB1") + " SB1  ON D3_COD = B1_COD "
_cQuery+= " WHERE SD3.D_E_L_E_T_ = ' ' AND SB1.D_E_L_E_T_ = ' ' "
_cQuery+= " AND D3_FILIAL = '"+cFilAnt+"'"
_cQuery+= " AND D3_ESTORNO <> 'S' "
_cQuery+= " AND D3_CF = 'PR0' "
_cQuery+= " AND D3_COD IN "+FormatIn(AllTrim(ZL6->ZL6_PRDRAT),";") 
_cQuery+= " AND D3_EMISSAO BETWEEN '"+DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery+= " GROUP BY D3_COD, B1_PESO "

MPSysOpenQuery( _cQuery ,"Rateio" )
	
_cValores+=_cQuery+CRLF+CRLF
While .NOT. Rateio->( Eof() )
    aAdd(_aProdsRateio,{AllTrim(Rateio->D3_COD),Rateio->PER_RAT})

    If _CodProd ==AllTrim(Rateio->D3_COD)
        _cValores+="* "+Rateio->D3_COD+" - "+Str(Rateio->PER_RAT,22,7)+CRLF
	Else	
        _cValores+=Rateio->D3_COD+" - "+Str(Rateio->PER_RAT,22,7)+CRLF
	EndIf	

	Rateio->( DBSkip() )
EndDo

Rateio->( DBCloseArea() )

If (nPos:=aScan(_aProdsRateio , {|A| A[1] == _CodProd })) <> 0
    Return _aProdsRateio[nPos,2]
EndIf

Return  0

/*
===============================================================================================================================
Programa----------: MEST9PMedio
Autor-------------: Alex Walaluer
Data da Criacao---: 10/07/2019
Descricao---------:  Baseado no Relatório de Faturamento de Vendas
Parametros--------: _cFilis,_cCodProd,_cClientes
Retorno-----------: Valor do Preço Medio
===============================================================================================================================
*/
Static Function MEST9PMedio(_cFilis,_cCodProd,_cClientes)

Local _cQuery:= ""
Local _cAlias := GetNextAlias()
Local _nPrecoMedia:=0

/* PARAMETROS DO RELATORIO CONSIDERADOS
ORDEM 3 e SINTETICO
DATA EMISSA DO MEST009
PRODUTO ZL6_PRODUTO
MV_PAR20: CFOPS = "V" E/OU "B"
FILTRA NF: SEDEX = 1 TODOS
MV_PAR22: ABATE DEVOLUCAO = SIM 
MV_PAR23: TIPO DEVOLUCAO = 1 
MV_PAR24: DATAS = DE CIMA STA
MV_PAR25: DATAS = DE CIMA STA
MV_PAR26: 1 - AMBAS 
MV_PAR28: 1 = AMBAS
MV_PAR29: 1 - AMBAS
*/                       
_cQuery+= " SELECT TT.QT D2_QUANT , TT.VBT D2_VALBRUT, E.QTE D1_QUANT, E.TOTE D1_TOTAL FROM ( "
_cQuery+= " SELECT T.QUANT QT,  T.VALBRUT VBT, T.FILIAL FT FROM ( "
_cQuery+= " SELECT S.D2_FILIAL FILIAL, S.D2_QUANT QUANT , V.D2_VALBRUT VALBRUT FROM  "
_cQuery+= " (SELECT D2_FILIAL, SUM(SD2.D2_QUANT) AS D2_QUANT  "
_cQuery+= "    FROM " + RetSqlName("SF2") + " SF2 " 
_cQuery+= "    JOIN " + RetSqlName("SD2") + " SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_cQuery+= "   WHERE SF2.D_E_L_E_T_ = ' ' AND SD2.D_E_L_E_T_ = ' '" 
_cQuery+= "     AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery+= "     AND SD2.D2_FILIAL = '"+cFilAnt+"' "
_cQuery+= "     AND SD2.D2_COD IN " + FormatIn(AllTrim(_cCodProd),";")
_cQuery+= "     AND (SD2.D2_CF IN " + FormatIn(U_ITCFOPS("V"),";")
_cQuery+= "       OR SD2.D2_CF IN " + FormatIn(AllTrim(U_ITCFOPS("B")),";")
_cQuery+= "          ) GROUP BY D2_FILIAL) S "
_cQuery+= "   INNER JOIN "
_cQuery+= " ( SELECT D2_FILIAL,  SUM(SD2.D2_VALBRUT) AS D2_VALBRUT"
_cQuery+= "    FROM " + RetSqlName("SF2") + " SF2 " 
_cQuery+= "    JOIN " + RetSqlName("SD2") + " SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_cQuery+= "   WHERE SF2.D_E_L_E_T_ = ' ' AND SD2.D_E_L_E_T_ = ' '" 
_cQuery+= "     AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery+= "     AND SD2.D2_FILIAL = '"+cFilAnt+"' "
_cQuery+= "     AND SD2.D2_COD IN " + FormatIn(AllTrim(_cCodProd),";")
_cQuery+= "     AND SD2.D2_CF IN " + FormatIn(U_ITCFOPS("V"),";")
_cQuery+= "     GROUP BY D2_FILIAL) V "
_cQuery+= "     ON V.D2_FILIAL = S.D2_FILIAL) T) TT"
_cQuery+= "   FULL OUTER JOIN "
_cQuery+= " ( SELECT D1_FILIAL FILIE, SUM(D1_QUANT)   AS QTE, SUM(D1_TOTAL+D1_ICMSRET) AS TOTE "
_cQuery+= "    FROM " + RetSqlName("SD1") + " SD1 "
_cQuery+= "    JOIN " + RetSqlName("SF1") + " SF1 ON D1_FILIAL = F1_FILIAL AND D1_DOC = F1_DOC AND D1_SERIE = F1_SERIE "
_cQuery+= "    WHERE SD1.D_E_L_E_T_ = ' '"
_cQuery+= "      AND D1_TIPO = 'D'   "
_cQuery+= "      AND F1_FORMUL = 'S' "
_cQuery+= "      AND SD1.D1_FILIAL = '"+cFilAnt+"' "
_cQuery+= "      AND SF1.F1_DTDIGIT BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"//  D1_EMISSAO  BETWEEN '20190601' AND '20190630'
_cQuery+= "      AND    TRIM(SD1.D1_NFORI)||TRIM(D1_SERIORI)||TRIM(D1_ITEMORI) IN  "
_cQuery+= "    ( SELECT TRIM(SD2.D2_DOC  )||TRIM(D2_SERIE  )||TRIM(D2_ITEM)    FROM " + RetSqlName("SF2") + " SF2 " 
_cQuery+= "                               JOIN " + RetSqlName("SD2") + " SD2 ON SD2.D2_DOC = SF2.F2_DOC AND SD2.D2_SERIE = SF2.F2_SERIE AND SD2.D2_FILIAL = SF2.F2_FILIAL "
_cQuery+= "         WHERE SF2.D_E_L_E_T_ = ' ' AND SD2.D_E_L_E_T_ = ' ' 
_cQuery+= "           AND SD2.D2_EMISSAO BETWEEN '" + DToS(MV_PAR05)+ "' AND '" + DToS(MV_PAR06) + "'"
_cQuery+= "           AND SD2.D2_FILIAL = '"+cFilAnt+"' "
_cQuery+= "           AND SD2.D2_COD IN " + FormatIn(AllTrim(_cCodProd),";")
_cQuery+= "           AND SD2.D2_CF IN " + FormatIn(U_ITCFOPS("V")+";"+AllTrim(U_ITCFOPS("B")),";")
_cQuery+= "     ) GROUP BY D1_FILIAL) E "
_cQuery+= "      ON TT.FT = E.FILIE "

_cValores:=_cQuery+CRLF+CRLF
nHandle := FCreate(_cdir+"SELECT_PRECO_MEDIO_Q_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cValores )
FClose(nHandle)

MPSysOpenQuery( _cQuery,_cAlias )

_cValores+=Str((_cAlias)->D2_QUANT,22,7)+CRLF
_cValores+=Str((_cAlias)->D1_QUANT,22,7)+CRLF
_nQTDE:=0
If .NOT. (_cAlias)->( Eof() )
   _nQTDE:=(_cAlias)->D2_QUANT - (_cAlias)->D1_QUANT
EndIf

_cValores+=Str((_cAlias)->D2_VALBRUT,22,7)+CRLF
_cValores+=Str((_cAlias)->D1_TOTAL,22,7)+CRLF
_nValor:=0
If .NOT. (_cAlias)->( Eof() )
   _nValor:=(_cAlias)->D2_VALBRUT-(_cAlias)->D1_TOTAL
EndIf
If _nValor > 0 .And. _nQTDE > 0
   _nPrecoMedia:=_nValor/_nQTDE
EndIf   
_cValores+=Str(_nPrecoMedia,22,7)+CRLF

(_cAlias)->( DBCloseArea() )

nHandle := FCreate(_cdir+"SELECT_PRECO_MEDIO_PM_"+cFilant+"__"+StrTran(TIME(),":","_")+".txt")
FWrite(nHandle, _cValores )
FClose(nHandle)

Return  _nPrecoMedia

/*
===============================================================================================================================
Programa----------: MEST2BuscaZE0
Autor-------------: Alex Walaluer
Data da Criacao---: 02/04/2019
Descricao---------: Retorna valor do mes anterior de perda valorizado
Parametros--------: nInd,_cChave,_cGrpCus,_cDSECT,_aTab
Retorno-----------: Valor do mes anterior de perda valorizado
===============================================================================================================================
*/
Static Function MEST2BuscaZE0(_cTPCUS,_cDGRPCT,_cDSECT,_aTab)

Local  _cMes:=Val(SubStr(DToS(MV_PAR05),5,2))//MES
Local _nVLRLT:=0

If _cMes = 1//JANEIRO
   _cMes:=Str( Val(SubStr(DToS(MV_PAR05),1,4)) - 1 , 4)+"12"
Else//FEV A DEZ
   _cMes:=SubStr(DToS(MV_PAR05),1,4) + StrZero(_cMes - 1 ,2)
EndIf
_cQuery := " SELECT ZE0_DATARQ , SUM(ZE0_VLRLT) ZE0_VLRLT FROM "+ RETSQLNAME("ZE0")+" ZE0"
_cQuery += " WHERE ZE0.D_E_L_E_T_ = ' ' "
_cQuery += " AND ZE0_DGRPCT = '"+_cDGRPCT+"' "
_cQuery += " AND ZE0_DEVCT = 'EMBALAGENS'
_cQuery += " AND SubStr(ZE0_DATARQ,3,4)||SubStr(ZE0_DATARQ,1,2)  <= '"+_cMes+"' "
_cQuery += " AND ZE0_TPCUS = '"+_cTPCUS+"' "
_cQuery += " GROUP BY ZE0_DATARQ "
_cQuery += " ORDER BY SubStr(ZE0_DATARQ,3,4) DESC, SubStr(ZE0_DATARQ,1,2) DESC "
MPSysOpenQuery( _cQuery, "ZE0T" ) 
ZE0T->(DBGoTop())
While ZE0T->(!Eof() )
	If !Empty(ZE0T->ZE0_VLRLT)
		_nVLRLT:=ZE0T->ZE0_VLRLT
		Exit
	EndIf   
	ZE0T->(DBSkip())
EndDo

Return _nVLRLT
