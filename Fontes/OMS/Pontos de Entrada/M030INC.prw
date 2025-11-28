/*
==================================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
==================================================================================================================================
 Autor       |    Data    |                              Motivo                      										 
----------------------------------------------------------------------------------------------------------------------------------
Josué Danich | 06/12/2016 | Chamado 17585. Inclusão de entidade contábil para novos fornecdores.
-------------------------------------------------------------------------- - -----------------------------------------------------
Darcio Sporl | 20/01/2017 | Chamado 17503. Foi incluído o tratamento para salvar o endereço ao executar o mashup. 
----------------------------------------------------------------------------------------------------------------------------------
Lucas Borges | 03/04/2018 | Chamado 24395. Incluída na regra da Conta Contábil o tipo L-Produtor Rural pois está sendo usado. 
----------------------------------------------------------------------------------------------------------------------------------
Julio Paz    | 12/09/2019 | Chamado 25540. Incluir validações específica para alteraçõo cliente 1/cliente 2 do cad.clientes.
----------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 03/04/2018 | Chamado 37363. Rollback para a revisão 1930 de 04/04/18 que é o que esta em produção atualmente.  
----------------------------------------------------------------------------------------------------------------------------------
Julio Paz    | 29/12/2021 | Chamado 30177. Inclusão de rotina para bloqueio e Workflow de clientes com desconto contratual. 
---------------------------------------------------------------------------------------------------------------------------------- 
Julio Paz    | 09/08/2022 | Chamado 40841. limpar conteúdo campos Suframa,quando cliente não fizer parte dos estados Suframa. 
----------------------------------------------------------------------------------------------------------------------------------
Julio Paz    | 09/08/2022 | Chamado 40931. Na incl/alt de funcionários, Gravar cad.Clientes:Segmento=39 e Tipo=Consumidor Final.
----------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 11/08/2022 | Chamado 40048. Ajuste para substituição de caracteres inválidos. 
----------------------------------------------------------------------------------------------------------------------------------
Igor Melgaço | 26/10/2022 | Chamado 40771. Correção de error.log variavel _lRet. 
----------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 17/02/2023 | Chamado 42425. Novo Tratamento para gravacao do campo A1_CONTRIB na nova Funcao CRMA980CON().
-------------------------------------------------------------------------------------------------------------------------------
Julio Paz    | 25/07/2023 | Chamado 44096. Ajustar rotina incl/alter gravar Grupo Tributação "023" p/Parana e Simples Nac
-------------------------------------------------------------------------------------------------------------------------------
Antonio Neves| 07/02/2024 | Chamado 46248. Adicionada as UFs AC - RO nos Estados do Suframa
==================================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa--------: M030INC
Autor-----------: Alexandre Villar
Data da Criacao-: 02/12/2015
===============================================================================================================================
Descrição-------: Ponto de entrada para gravar os dados do cadastro do Cliente após a inclusão.
===============================================================================================================================
Parametros------: ParamIXB -> Numérico -> Tipo da operação do usuário. Conteúdo 3 significa que o usuário cancelou a inclusão.
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function M030INC()

Local _aArea	:= FWGetArea()
Local _cConta	:= ''
Local _cEnd		:= ''

Local _lMashup	:= U_ItGetMV("IT_MASHUP",.F.)

Local _nQtdDia	:= 0
Local _nQtdiaT	:= 0
Local _lExec	:= .F.

Local _lLibMas	:= .F.
Local _aBloqSA1

Local _cA1_NOME    := ""
Local _cA1_END     := ""
Local _cA1_BAIRRO  := ""
Local _cA1_ENDCOB  := ""
Local _cA1_ENDREC  := ""
Local _cA1_ENDENT  := ""
Local _cA1_BAIRROE := ""
Local _lRet        := .T.

Local _cUfMVA := U_ITGetMV("IT_UFSMVA","PR")
Local _cTRIBMVA := U_ITGetMV("IT_TRIBMVA","023")

//====================================================================================================
// Verifica a configuração do cadastro para ajustar a conta contábil
//====================================================================================================
Do Case
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'AM' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069992'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RS' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069993'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'MG' .And. SA1->A1_PESSOA == 'F' .And. SA1->A1_COD_MUN == '69307' //Três Corações
		_cConta := '1102069995'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'SP' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069996'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST $ 'MG/GO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069998'
	
	Case SA1->A1_TIPO $ 'F/L' .And. SA1->A1_EST == 'RO' .And. SA1->A1_PESSOA == 'F'
		_cConta := '1102069999'
	
EndCase

If !Empty( _cConta ) .And. _cConta <> SA1->A1_CONTA
	
	RecLock( 'SA1' , .F. )
	SA1->A1_CONTA := _cConta
	SA1->( MSUnLock() )
	
EndIf     
                 
//===================================================================================
// Grava os dados dos clientes nas tabelas de muro para integração com o sistema RDC.
//===================================================================================
If Type("M->A1_COD") <> "U" // Indica que foi confirmado uma inclusão.
   U_AOMS076G()
EndIf

//================================================================================
// Cria item contábil para o novo fornecedor
//================================================================================
CTD->(DBSetOrder(1))

If .not. CTD->(DBSeek(xFilial("CTD")+"SA1"+ AllTrim(SA1->A1_COD)))

  RecLock("CTD", .T.)

  CTD->CTD_ITEM := "SA1" + AllTrim(SA1->A1_COD)
  CTD->CTD_DESC01 := SA1->A1_NOME
  CTD->CTD_BLOQ :=  "2"
  CTD->CTD_DTEXIS := SToD("19800101")
  CTD->CTD_ITLP := "SA2" + AllTrim(SA1->A1_COD)
  CTD->CTD_CLOBRG := "2"
  CTD->CTD_ACCLVL := "1"
  CTD->CTD_CLASSE := "2"

  MSUnLock()
  
EndIf

If _lMashup

	_cUser := RetCodUsr()
			
	DBSelectArea("ZZL")
	ZZL->( DBSetOrder(3) )
	If ZZL->( DBSeek( xFilial("ZZL") + _cUser ) )
		If ZZL->ZZL_LIBMAS == "S"
			_lLibMas := .T.
		EndIf
	EndIf
	
	If SA1->A1_PESSOA <> "F"
		_nQtdDia	:= Val(SA1->A1_I_PEREX)
		_nQtdiaT	:= IIf(Empty(M->A1_I_DTEXE),0,dDataBase - M->A1_I_DTEXE)
		_lExec		:= IIf(_nQtdiaT > _nQtdDia, .T., .F.)
		If !_lLibMas .Or. _lExec
			If IsInCallStack("MA030Trans")
				If !Empty(SA1->A1_I_END) .And. Empty(SA1->A1_I_NUM)
					_cEnd := AllTrim(SA1->A1_I_END)
				ElseIf !Empty(SA1->A1_I_END) .And. !Empty(SA1->A1_I_NUM)
					_cEnd := AllTrim(SA1->A1_I_END) + ", " + AllTrim(SA1->A1_I_NUM)
				EndIf
			
				RecLock("SA1", .F.)
				SA1->A1_END		:= _cEnd
				SA1->A1_I_DTEXE	:= Date()
				SA1->(MSUnLock())
			EndIf
		Else
			RecLock("SA1", .F.)
			SA1->A1_I_DTEXE := Date()
			SA1->(MSUnLock())
		EndIf
	EndIf
EndIf
/*
If Empty(SA1->A1_INSCR) .Or. AllTrim(SA1->A1_INSCR) == "ISENTO"
	RecLock("SA1", .F.)
	SA1->A1_CONTRIB := "2"
	SA1->(MSUnLock())
Else
	RecLock("SA1", .F.)
	SA1->A1_CONTRIB := "1"
	SA1->(MSUnLock())
EndIf*/

U_CRMA980CON()//Funcao do P.E. CRMA980PE.PRW

//=======================================================================
// Verifica se as validações da rotina de desconto contratual se 
// deve bloquear o Cliente. Caso afirmativo bloqueia o cliente por 
// Desconto Contratual.
//=======================================================================
_aBloqSA1 := U_MA30RETA()
If ValType(_aBloqSA1) == "A" .And. Len(_aBloqSA1) > 0 .And. ValType(_aBloqSA1[1]) == "L" .And. _aBloqSA1[1] // Bloqueia SA1 por Desconto Contratual = True or False
   SA1->(RecLock("SA1",.F.))
   SA1->A1_MSBLQL  := "1" // Bloqueio por Cliente
   SA1->A1_I_BLQDC := "1"
   SA1->(MSUnLock())
   
   //==================================================================
   // Envia Workflow de bloqueio de clientes por desconto contratual.
   //==================================================================
   U_M30PALWF()

EndIf 

//Substituição de caracteres de Campos
SA1->(RecLock("SA1", .F.))

_cA1_NOME := SA1->A1_NOME
If !Empty(AllTrim(M->A1_NOME))
	_lRet := U_CRMA980VCP(@_cA1_NOME   ,"A1_NOME")
	SA1->A1_NOME := _cA1_NOME
EndIf

_cA1_END := SA1->A1_END
If _lRet .And. !Empty(AllTrim(_cA1_END))
	_lRet := U_CRMA980VCP(@_cA1_END    ,"A1_END")
	SA1->A1_END := _cA1_END
EndIf

_cA1_BAIRRO := SA1->A1_BAIRRO
If _lRet .And. !Empty(AllTrim(_cA1_BAIRRO))
	_lRet := U_CRMA980VCP(@_cA1_BAIRRO ,"A1_BAIRRO")
	SA1->A1_BAIRRO := _cA1_BAIRRO
EndIf

_cA1_ENDCOB := M->A1_ENDCOB
If _lRet .And. !Empty(AllTrim(_cA1_ENDCOB))
	_lRet := U_CRMA980VCP(@_cA1_ENDCOB ,"A1_ENDCOB")
	SA1->A1_ENDCOB := _cA1_ENDCOB
EndIf

_cA1_ENDREC := M->A1_ENDREC
If _lRet .And. !Empty(AllTrim(_cA1_ENDREC))
	_lRet := U_CRMA980VCP(@_cA1_ENDREC ,"A1_ENDREC")
	SA1->A1_ENDREC := _cA1_ENDREC
EndIf

_cA1_ENDENT := M->A1_ENDENT
If _lRet .And. !Empty(AllTrim(_cA1_ENDENT))
	_lRet := U_CRMA980VCP(@_cA1_ENDENT,"A1_ENDENT")
	SA1->A1_ENDENT := _cA1_ENDENT
EndIf

_cA1_BAIRROE := M->A1_BAIRROE
If _lRet .And. !Empty(AllTrim(_cA1_BAIRROE))
	_lRet := U_CRMA980VCP(@_cA1_BAIRROE,"A1_BAIRROE")
	SA1->A1_BAIRROE := _cA1_BAIRROE
EndIf

SA1->(MSUnLock())
//=====================================================================
// Para os clientes que não são dos estados "AM-RR-AP" gravar os campos
// suframa com: A1_CALCSUF = "N" e A1_SUFRAMA = " ".
//=====================================================================
If ! (SA1->A1_EST $ "AM-RR-AP-AC-RO")
   SA1->(RecLock("SA1",.F.))
   SA1->A1_CALCSUF := "N"
   SA1->A1_SUFRAMA := " "
   SA1->(MSUnLock())
EndIf

//=====================================================================
// Para os clientes que são funcionários, gravar tipo e seguimento
// como consumidor final.
//=====================================================================
If SA1->A1_CLIFUN == "1"
   SA1->(RecLock("SA1",.F.))
   SA1->A1_TIPO    := "F"  //  Tipo = Consumidor Final
   SA1->A1_I_GRCLI := "39" //  Seguimento = Consumidor Final   
   SA1->(MSUnLock())   
EndIf 

//=====================================================================
// Para os clientes do Paraná optantes pelo Simples Nacional grava
// grava o campo Grupo Tributário com "023", para obterem benefícios.
//=====================================================================
If SA1->A1_EST $ _cUfMVA .And. SA1->A1_SIMPNAC == "1" // 1=Sim;2=Não
   SA1->(RecLock("SA1",.F.))
   SA1->A1_GRPTRIB := _cTRIBMVA //"023" //  Motivo: estado reduz o MVA para 30% (exceção fiscal) e estamos iniciando operação de 4 Brokers que atenderão este grupo.
   SA1->(MSUnLock())
EndIf 

FWRestArea(_aArea)
Return
