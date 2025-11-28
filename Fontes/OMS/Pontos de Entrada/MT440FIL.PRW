/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 07/03/2017 | Ajustes da Validação de crédito - Chamado 19169
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 10/04/2017 | Incluido filtros por pedidos de funcionários - Chamado 19537
-------------------------------------------------------------------------------------------------------------------------------
 Lucas Borges     | 11/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
-------------------------------------------------------------------------------------------------------------------------------
 Alex Wallauer    | 01/02/2021 | Remoção de bugs apontados pelo Totvs CodeAnalysis. Chamado: 34262
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "RwMake.ch"
Static aLog:={}

/*
=========================================================================================================================================================
Programa----------: MT440FIL
Autor-------------: Alex Wallauer
Data da Criacao---: 07/03/2017
=========================================================================================================================================================
Descrição---------: PE na Function a440Proces() do programa Mata440.PRX
===============================================================================================================================
Uso---------------: Liberacao de Pedidos de Vendas Automatica 
=========================================================================================================================================================
Parametros--------: Nenhum
=========================================================================================================================================================
Observação--------: 
=========================================================================================================================================================
*/
User Function MT440FIL()

Local _cBlqCred:=""
Local _lvalida := .T.
Local _nTotal := 0
Local _cFiltro:=""
Local _cFiltroF:="(.F.)"
Local _cChep   := AllTrim(GetMV("IT_CCHEP"))

_aSC5:= GetArea("SC5") 

SC5->( DBSetOrder(1))
SC5->( DBSeek(SC6->C6_FILIAL+SC6->C6_NUM) )//Posiciona na capa

IncProc("Lendo PV: "+SC6->C6_FILIAL+" - "+SC6->C6_NUM)

//====================================================================================================
// Filtros de pedidos de funcionários
//====================================================================================================
If MV_PAR11 == 1

   If SC5->C5_I_OPER == "02" .And. SC5->C5_TIPO == "N" //.And. Upper(AllTrim(SC5->C5_I_OBPED)) == "PEDIDO AUTOMÁTICO - AOMS070"
      _cFiltro := ""
   Else
      FWRestArea(_aSC5)	
      Return _cFiltroF
   EndIf

EndIf

If (_nPos:= aScan(aLog , {|L| L[3] == SC6->C6_NUM })) # 0
   If aLog[_nPos,1]//.T.
      Return _cFiltro
   Else//.F.
      Return _cFiltroF
   EndIf
EndIf

_nREC_SC6:= SC6->(RecNo()) 
_aSC6    := GetArea("SC6") 
_aSC9    := GetArea("SC9") 
_aSF4    := GetArea("SF4") 

SC6->( DBSetOrder(1))
SC6->( DBSeek(SC5->C5_FILIAL+SC5->C5_NUM) )//Reposiciona o SC6 no primeiro item do PV

While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM

   If AllTrim(SC6->C6_PRODUTO) == _cChep .Or. AllTrim(SC6->C6_CF) $ '5910/6910/5911/6911'
   
      //NÃO VALIDA CRÉDITO PARA PALLET CHEP E PARA BONIFICAÇÃO
      _lvalida := .F.
      
    EndIf
    
    If SC5->C5_TIPO != 'N' .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") != 'S' 
   
      //NÃO VALIDA CRÉDITO PARA PEDIDO SEM DUPLICATA OU PARA PEDIDO QUE NÃO SEJA PEDIDO NORMAL
      _lvalida := .F.
      
    EndIf
    
    If Posicione("ZAY",1,xFilial("ZAY")+SC6->C6_CF,"ZAY_TPOPER") != 'V' 
   
      //NÃO VALIDA CRÉDITO PARA PEDIDO COM CFOP QUE NÃO SEJA DE VENDA
      _lvalida := .F.
      
    EndIf

    If !_lvalida
       Exit
    EndIf   

   _nTotal += SC6->C6_VALOR
   
   SC6->( DBSkip() )
	
EndDo

//AWF-30/11/2016 - Reavaliação de Credito
If _lvalida .And. SC5->C5_I_BLCRE = "B" 
   cMensagem:="O pedido não pode ser liberado pois esta bloqueado para avaliação"
   aAdd(aLog,{ .F. , SC5->C5_FILIAL , SC5->C5_NUM , "Não" , cMensagem })
   _cFiltro := _cFiltroF
EndIf   

If _lvalida .And. Empty(_cFiltro)

//********************** VALIDACAO NOVA DE CREDITO UNIFICADA ***************************************************//		
   _aRetCre := U_ValidaCredito( _nTotal )//AWF-11/01/2017
   _cBlqCred:=_aRetCre[1]
//********************** VALIDACAO NOVA DE CREDITO UNIFICADA ***************************************************//		

   If _cBlqCred != "Liberação completa de crédito" .And. _cBlqCred != "Liberado por risco A" .And. _cBlqCred != "Aprovado em análise de crédito"

      SC5->(RecLock("SC5",.F.))
	  SC5->C5_I_BLCRE := "B"
	  SC5->C5_I_DTAVA := Date()
	  SC5->C5_I_HRAVA := Time()
	  SC5->C5_I_USRAV := cUserName
	  SC5->C5_I_MOTBL := _cBlqCred

	  SC5->C5_I_LIBCA := ""
	  SC5->C5_I_LIBC  := 0
	  SC5->C5_I_LIBCT := ""
	  SC5->C5_I_LIBL  := CTOD("")
	  SC5->C5_I_LIBCV := 0
	  SC5->C5_I_LIBCD := CTOD("")
	  SC5->C5_I_DTLIC := CTOD("")

   	  SC5->(MSUnLock())
  
      cMensagem:="O pedido não pode ser liberado e será bloqueado para posterior avaliação [ "+_cBlqCred+" ]"
      
      aAdd(aLog,{ .F.  , SC5->C5_FILIAL , SC5->C5_NUM , "Não" , cMensagem })

      _cFiltro := _cFiltroF
   
   ElseIf SC5->C5_I_BLCRE != "L"
   
      SC5->(RecLock("SC5",.F.))
	  SC5->C5_I_BLCRE := " "
	  SC5->C5_I_DTAVA := Date()
	  SC5->C5_I_HRAVA := Time()
	  SC5->C5_I_USRAV := cUserName
	  SC5->C5_I_MOTBL := _cBlqCred
   	  SC5->(MSUnLock())
   
   EndIf

EndIf
//AWF-30/11/2016 - Reavaliação de Credito

If Empty(_cFiltro)

   aAdd(aLog,{ .T. , SC5->C5_FILIAL , SC5->C5_NUM ," ", "Pedido Liberado" })

EndIf 

FWRestArea(_aSC5)	
FWRestArea(_aSC6)	
FWRestArea(_aSC9)	
FWRestArea(_aSF4)	

SC6->(DBGoTo(_nREC_SC6)) 

Return _cFiltro

*====================================================*
User Function MT440LOG(lLimpa)
*====================================================*
If lLimpa
   aLog:={}
EndIf

Return aLog
