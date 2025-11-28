/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges  |08/10/2024| Chamado 48465. Retirada manipulação do SX1
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include 'FWMVCDEF.CH'
#Include "TOTVS.ch"
#Include "topconn.ch"

/*
===============================================================================================================================
Programa--------: AOMS122
Autor-----------: Julio de Paula Paz
Data da Criacao-: 19/03/2021
===============================================================================================================================
Descrição-------: Rotina para adicionar ou subtrair percentual de valores em campos de valores da tabela de preços.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Codigo do Vendedor responsavel pela venda
===============================================================================================================================*/
User Function AOMS122()

Local _lRet := .F.

Private _oBrowse
Private CCADASTRO := "Regras de Tabelas de Preços"
Private INCLUI  := .F., LCOPIA := .F.
Private aRotina := Menudef()
Private _aFields := {} //_aColumns := {}
Private _nTotRegs := 0
Private _oMrkBrowse, _cTipoReajuste  

Begin Sequence

   If ! Pergunte("AOMS122",.T.)
      Break
   EndIf
   
   If MV_PAR05 <> 1 .And. MV_PAR06 <> 1 .And. MV_PAR07 <> 1 .And. MV_PAR08 <> 1
      U_ITMsg("Para rodar esta rotina é obrigatório selecionar como 'SIM',"+ ;
              " pelo menos um dos campos : 'Ajusta PR Carga Fech', 'Ajusta PR Min Carga Fech'," + ; 
              " 'Ajusta PR Carga Fra', 'Ajusta PR Min Carga Frac.'","Atenção",,1)
      Break
   EndIf

   If MV_PAR09 == 0
      U_ITMsg("O preenchimento do percentual de reajuste é obrigatório.","Atenção",,1)
      Break
   EndIf

   //======================================================
   // Roda a query de dados e Cria a Tabela Temporária.
   //======================================================
   
   FWMsgRun( ,{|_oProc| _lRet := U_AOMS122Q(_oProc) } , 'Aguarde...' , 'Efetuando Leitura dos dados...' )
    
   If ! _lRet 
      U_ITMsg("Não foram encontrados dados que satisfazem as condições de filtros.","Atenção",,1)
      Break 
   EndIf 

   If MV_PAR10 == 1 
     _cTipoReajuste := "Adicionando: " + AllTrim(Str(MV_PAR09,8,4))
   Else
     _cTipoReajuste := "Subtraindo: " + AllTrim(Str(MV_PAR09,8,4))
   EndIf
   
   _cTipoReajuste := _cTipoReajuste + "%"

	//======================================================
	// Criação da MarkBrowse
	//======================================================
	_oMrkBrowse:= FWMarkBrowse():New()
	_oMrkBrowse:SetDataTable(.T.)
	_oMrkBrowse:SetAlias("TRBDA1")
	_oMrkBrowse:SetDescription("Ajustes de tabelas de preços - Tela de Conferência e Confirmação ["+_cTipoReajuste+"]")
   _oMrkBrowse:SetFields( _aFields )													 		// Campos para exibição
   _oMrkBrowse:SetFilter("DA1_FILIAL", "01", "01") // Exibe na tela apenas a filial 01. Na gravação, as alterações são replicadas para as demais filiais.
	_oMrkBrowse:Activate()

End Sequence

If Select("TRBDA1") <> 0
	TRBDA1->(DBCloseArea())
EndIf

Return 

/*
===============================================================================================================================
Programa----------: MenuDef
Autor-------------: Julio de Paula Paz
Data da Criacao---: 23/03/2021                            .
===============================================================================================================================
Descrição---------: Rotina para criação do menu da tela principal
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: _aRotina - Array com as opções de menu.
===============================================================================================================================
*/
Static Function MenuDef()
Local _aRotina := {}

ADD OPTION _aRotina Title 'Grava Dados'	Action 'U_AOMS122G'	OPERATION 2 ACCESS 0
ADD OPTION _aRotina Title 'Exporta Excel' Action 'U_AOMS122E'	OPERATION 3 ACCESS 0

Return(_aRotina)

/*
===============================================================================================================================
Programa--------: AOMS122Q
Autor-----------: Julio de Paula Paz
Data da Criacao-: 19/03/2021
===============================================================================================================================
Descrição-------: Roda a query e grava tabela temporária com ajustes da tabela de preços.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: _lRet = .T. = Há dados a serem processados
                          .F. = Não há dados a serem processados.
===============================================================================================================================*/
User Function AOMS122Q(_oProc)
Local _cQry 
Local _aStruct := {}
Local _lRet := .F., _nI 
Local _nValor1, _nValor2, _nValor3, _nValor4
Local _cDescTab, _cDescProd

Begin Sequence

   //=================================================================
   // Monta a query de dados
   //=================================================================
   _cQry := "SELECT R_E_C_N_O_ AS NRRECNO "
   _cQry += " FROM " + RetSqlName("DA1") + " DA1 "
   _cQry += " WHERE DA1.D_E_L_E_T_ = ' ' 
   
   If ! Empty(MV_PAR01) // Codigos de tabelas de preços. 
      _cQry +=  " AND DA1_CODTAB IN " + FormatIn(MV_PAR01,";")
   EndIf
   
   If ! Empty(MV_PAR02)
      _cQry +=  " AND DA1_I_MIX = '" + MV_PAR02 + "' " // MIX   
   EndIf 
    
   If ! Empty(MV_PAR03)
      _cQry +=  " AND DA1_GRUPO IN "+ FormatIn(MV_PAR03,";")   // GRUPO 
   EndIf 
   
   If ! Empty(MV_PAR04)
      _cQry +=  " AND DA1_CODPRO IN " + FormatIn(MV_PAR04,";")  // PRODUTO 
   EndIf

   If Select("QRYDA1") <> 0
	  QRYDA1->(DBCloseArea())
   EndIf
	
   TCQUERY _cQry NEW ALIAS "QRYDA1"	
   	
   DBSelectArea("QRYDA1")
   Count To _nTotRegs

   QRYDA1->(DBGoTop())

   If _nTotRegs == 0 // QRYDA1->(Eof()) .Or. QRYDA1->(Bof())
      Break 
   EndIf 

   _lRet := .T. 

   //=================================================================
   // Cria a tabela temporária
   //=================================================================
   aAdd(_aStruct,{"DA1_FILIAL", "C",  2, 0})
   aAdd(_aStruct,{"DA1_CODTAB", "C",  3, 0})
   aAdd(_aStruct,{"DA1_DESTAB", "C", 30, 0})
   aAdd(_aStruct,{"DA1_I_MIX ", "C",  2, 0})
   aAdd(_aStruct,{"DA1_GRUPO ", "C",  4, 0})
   aAdd(_aStruct,{"DA1_CODPRO", "C", 15, 0})
   aAdd(_aStruct,{"DA1_DESCRI", "C", 80, 0})
   aAdd(_aStruct,{"DA1_PRCVEN", "N",  9, 2})  //  "PR Carga Fech"
   aAdd(_aStruct,{"WK_PRCVEN" , "N",  9, 2})  //  "Reaj.PR Carga Fech"
   aAdd(_aStruct,{"DA1_I_PMFE", "N",  9, 2})  //  "PR Min Carga Fech"
   aAdd(_aStruct,{"WK_I_PMFE" , "N",  9, 2})  //  "Reaj.PR Min Carga Fech"
   aAdd(_aStruct,{"DA1_I_PRFE", "N",  9, 2})  //  "PR Carga Frac"
   aAdd(_aStruct,{"WK_I_PRFE" , "N",  9, 2})  //  "Reaj.PR Carga Frac"
   aAdd(_aStruct,{"DA1_I_PMFR", "N",  9, 2})  //  "PR Min Carga Frac"
   aAdd(_aStruct,{"WK_I_PMFR" , "N",  9, 2})  //  "Reaj.PR Min Carga Frac"
   aAdd(_aStruct,{"DA1_I_PRCA", "N",  9, 2})  //  "Preco Maximo"
   aAdd(_aStruct,{"WK_I_PRCA", "N",  9, 2})   //  "Reaj.Preco Maximo"
   aAdd(_aStruct,{"DA1_PRCMAX", "N", 14, 2})  //  "Preco Maximo"
   aAdd(_aStruct,{"WK_PRCMAX", "N", 14, 2})   //  "Reaj.Preco Maximo"
   aAdd(_aStruct,{"DA1_RECNO" , "N", 10,0 })

   //=============================================================================
   // Montando o _aFields do FWMarkBrowse.
   //=============================================================================
   //                         Titulo     Code-Block   Tipo          Picture  Alinhamento  Tamanho  Decimal
   aAdd(_aFields, {RetTitle("DA1_CODTAB"),{|| TRBDA1->DA1_CODTAB}, "C", "@!", 1,TamSX3("DA1_CODTAB")[1],TamSX3("DA1_CODTAB")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_DESTAB"),{|| TRBDA1->DA1_DESTAB}, "C", "@!", 1,TamSX3("DA1_DESTAB")[1],TamSX3("DA1_DESTAB")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_I_MIX"),{|| TRBDA1->DA1_I_MIX}, "C", "@!", 1,TamSX3("DA1_I_MIX")[1],TamSX3("DA1_I_MIX")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_GRUPO"),{|| TRBDA1->DA1_GRUPO}, "C", "@!", 1,TamSX3("DA1_GRUPO")[1],TamSX3("DA1_GRUPO")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_CODPRO"),{|| TRBDA1->DA1_CODPRO}, "C", "@!", 1,TamSX3("DA1_CODPRO")[1],TamSX3("DA1_CODPRO")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_DESCRI"),{|| TRBDA1->DA1_DESCRI}, "C", "@!", 1,TamSX3("DA1_DESCRI")[1],TamSX3("DA1_DESCRI")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_PRCVEN"),{|| TRBDA1->DA1_PRCVEN}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_PRCVEN")[1],TamSX3("DA1_PRCVEN")[2]}) 
   aAdd(_aFields, {"Reajuste: PR Carga Fech",{|| TRBDA1->WK_PRCVEN}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_PRCVEN")[1],TamSX3("DA1_PRCVEN")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_I_PMFE"),{|| TRBDA1->DA1_I_PMFE}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PMFE")[1],TamSX3("DA1_I_PMFE")[2]}) 
   aAdd(_aFields, {"Reajuste: PR Min Carga Fech",{|| TRBDA1->WK_I_PMFE}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PMFE")[1],TamSX3("DA1_I_PMFE")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_I_PRFE"),{|| TRBDA1->DA1_I_PRFE}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PRFE")[1],TamSX3("DA1_I_PRFE")[2]}) 
   aAdd(_aFields, {"Reajuste: PR Carga Frac",{|| TRBDA1->WK_I_PRFE}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PRFE")[1],TamSX3("DA1_I_PRFE")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_I_PMFR"),{|| TRBDA1->DA1_I_PMFR}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PMFR")[1],TamSX3("DA1_I_PMFR")[2]}) 
   aAdd(_aFields, {"Reajuste: PR Min Carga Frac",{|| TRBDA1->WK_I_PMFR}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PMFR")[1],TamSX3("DA1_I_PMFR")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_I_PRCA"),{|| TRBDA1->DA1_I_PRCA}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PRCA")[1],TamSX3("DA1_I_PRCA")[2]}) 
   aAdd(_aFields, {"Reajuste: Preco Maximo 1",{|| TRBDA1->WK_I_PRCA}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_I_PRCA")[1],TamSX3("DA1_I_PRCA")[2]}) 
   aAdd(_aFields, {RetTitle("DA1_PRCMAX"),{|| TRBDA1->DA1_PRCMAX}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_PRCMAX")[1],TamSX3("DA1_PRCMAX")[2]}) 
   aAdd(_aFields, {"Reajuste: Preco Maximo 2",{|| TRBDA1->WK_PRCMAX}, "N", "@E 999,999,999.99", 2,TamSX3("DA1_PRCMAX")[1],TamSX3("DA1_PRCMAX")[2]}) 

   If Select("TRBDA1") <> 0
	   TRBDA1->(DBCloseArea())
   EndIf
   
   //======================================================================
   // Cria arquivo de dados temporário
   //======================================================================
   _oTemp := FWTemporaryTable():New( "TRBDA1",  _aStruct )
   _otemp:AddIndex( "01", {"DA1_CODTAB","DA1_CODPRO"} ) // GERENTE/COORDENADOR/VENDEDOR
   _otemp:Create()

   //==========================================================================
   // Grava na tabela temporária os dados da Query e os cálculos de reajustes.
   //==========================================================================
   _nI := 1

   While ! QRYDA1->(Eof())
      _oProc:cCaption := ("Atualizando valores..." + AllTrim(Str(_nI,10)) + "/" + AllTrim(Str(_nTotRegs,10)))
      ProcessMessages()

      DA1->(DBGoTo(QRYDA1->NRRECNO))
      
      _nValor1 := DA1->DA1_PRCVEN * (MV_PAR09 / 100) // "PR Carga Fech"
      _nValor2 := DA1->DA1_I_PMFE * (MV_PAR09 / 100) // "PR Min Carga Fech"
      _nValor3 := DA1->DA1_I_PRFE * (MV_PAR09 / 100) // "PR Carga Frac"
      _nValor4 := DA1->DA1_I_PMFR * (MV_PAR09 / 100) // "PR Min Carga Frac"

      _cDescTab  := Posicione("DA0",1,xFilial("DA0")+DA1->DA1_CODTAB,"DA0_DESCRI")
      _cDescProd := Posicione("SB1",1,xFilial("SB1")+DA1->DA1_CODPRO,"B1_DESC")

      TRBDA1->(RecLock("TRBDA1",.T.))
      TRBDA1->DA1_FILIAL := DA1->DA1_FILIAL 
      TRBDA1->DA1_CODTAB := DA1->DA1_CODTAB
      TRBDA1->DA1_DESTAB := _cDescTab
      TRBDA1->DA1_I_MIX  := DA1->DA1_I_MIX 
      TRBDA1->DA1_GRUPO  := DA1->DA1_GRUPO
      TRBDA1->DA1_CODPRO := DA1->DA1_CODPRO
      TRBDA1->DA1_DESCRI := _cDescProd
      TRBDA1->DA1_PRCVEN := DA1->DA1_PRCVEN
      TRBDA1->WK_PRCVEN  := DA1->DA1_PRCVEN
      TRBDA1->DA1_I_PMFE := DA1->DA1_I_PMFE
      TRBDA1->WK_I_PMFE  := DA1->DA1_I_PMFE
      TRBDA1->DA1_I_PRFE := DA1->DA1_I_PRFE
      TRBDA1->WK_I_PRFE  := DA1->DA1_I_PRFE
      TRBDA1->DA1_I_PMFR := DA1->DA1_I_PMFR
      TRBDA1->WK_I_PMFR  := DA1->DA1_I_PMFR
      TRBDA1->DA1_I_PRCA := DA1->DA1_I_PRCA
      TRBDA1->WK_I_PRCA  := DA1->DA1_I_PRCA
      TRBDA1->DA1_PRCMAX := DA1->DA1_PRCMAX
      TRBDA1->WK_PRCMAX  := DA1->DA1_PRCMAX 
      TRBDA1->DA1_RECNO  := DA1->(Recno())  

      If MV_PAR10 == 1 // Aumentar valor
      
         If MV_PAR05 == 1 // "PR Carga Fech"
            TRBDA1->WK_PRCVEN := DA1->DA1_PRCVEN + _nValor1// "PR Carga Fech"
            TRBDA1->WK_I_PRCA  := (DA1->DA1_PRCVEN + _nValor1) * 1.10   // Acrescentando 10% como valor máximo.
            TRBDA1->WK_PRCMAX  := (DA1->DA1_PRCVEN + _nValor1) * 1.10   // Acrescentando 10% como valor máximo.
         EndIf 
      
         If MV_PAR06 == 1
            TRBDA1->WK_I_PMFE := DA1->DA1_I_PMFE + _nValor2// "PR Min Carga Fech"
         EndIf 
      
         If MV_PAR07 == 1
            TRBDA1->WK_I_PRFE := DA1->DA1_I_PRFE + _nValor3 // "PR Carga Frac"
            If MV_PAR05 <> 1 // Preço máximo não definido no campo Preço Carga Fechada.
               TRBDA1->WK_I_PRCA  := (DA1->DA1_I_PRFE + _nValor3) * 1.10   // Acrescentando 10% como valor máximo.
               TRBDA1->WK_PRCMAX  := (DA1->DA1_I_PRFE + _nValor3) * 1.10   // Acrescentando 10% como valor máximo.
            EndIf     
         EndIf 
      
         If MV_PAR08 == 1
            TRBDA1->WK_I_PMFR := DA1->DA1_I_PMFR + _nValor4// "PR Min Carga Frac"
         EndIf 

      Else // Diminuir valor

         If MV_PAR05 == 1 // "PR Carga Fech"
            TRBDA1->WK_PRCVEN := DA1->DA1_PRCVEN - _nValor1// "PR Carga Fech"
            TRBDA1->WK_I_PRCA  := (DA1->DA1_PRCVEN - _nValor1) * 1.10   // Acrescentando 10% como valor máximo.
            TRBDA1->WK_PRCMAX  := (DA1->DA1_PRCVEN - _nValor1) * 1.10   // Acrescentando 10% como valor máximo.
         EndIf 
      
         If MV_PAR06 == 1
            TRBDA1->WK_I_PMFE := DA1->DA1_I_PMFE - _nValor2// "PR Min Carga Fech"
         EndIf 
      
         If MV_PAR07 == 1
            TRBDA1->WK_I_PRFE := DA1->DA1_I_PRFE - _nValor3 // "PR Carga Frac"
            If MV_PAR05 <> 1 // Preço máximo não definido no campo Preço Carga Fechada.
               TRBDA1->WK_I_PRCA  := (DA1->DA1_I_PRFE - _nValor3) * 1.10   // Acrescentando 10% como valor máximo.
               TRBDA1->WK_PRCMAX  := (DA1->DA1_I_PRFE - _nValor3) * 1.10   // Acrescentando 10% como valor máximo.
            EndIf     
         EndIf 
      
         If MV_PAR08 == 1
            TRBDA1->WK_I_PMFR := DA1->DA1_I_PMFR - _nValor4// "PR Min Carga Frac"
         EndIf 

      EndIf
      
      TRBDA1->(MSUnLock())        

      QRYDA1->(DBSkip())
      
      _nI += 1

   EndDo

End Sequence

If Select("QRYDA1") <> 0
   QRYDA1->(DBCloseArea())
EndIf

Return _lRet 

/*
===============================================================================================================================
Programa--------: AOMS122G
Autor-----------: Julio de Paula Paz
Data da Criacao-: 24/03/2021
===============================================================================================================================
Descrição-------: Rotina de gravação dos dados reajustados.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================*/
User Function AOMS122G()
Local _nI := 1

Begin Sequence 

   If ! U_ITMsg("Confirma a gravação dos dados?","Atenção" , , ,2, 2) 
      Break 
   EndIf
   
   DA0->(DBSetOrder(1)) // DA0_FILIAL+DA0_CODTAB 

   TRBDA1->(DBGoTop())
   While ! TRBDA1->(Eof())
      
      DA1->(DBGoTo(TRBDA1->DA1_RECNO))
      DA0->(DBSeek(xFilial("DA0")+DA1->DA1_CODTAB))

      //===================================================================
      // Grava log de alteração.
      //===================================================================
      ZGS->(RecLock("ZGS",.T.))
		ZGS->ZGS_FILIAL := xFilial("ZGS")
		ZGS->ZGS_ITEM   := DA1->DA1_ITEM
		ZGS->ZGS_DATA   := Date()
		ZGS->ZGS_HORA   := Time()
		ZGS->ZGS_USER   := cUserName
		ZGS->ZGS_MODULO := funname()	
		ZGS->ZGS_CODTAB := DA0->DA0_CODTAB
		ZGS->ZGS_DATDE 	:= DA0->DA0_DATDE
		ZGS->ZGS_HORADE	:= DA0->DA0_HORADE
		ZGS->ZGS_DATATE	:= DA0->DA0_DATATE
		ZGS->ZGS_HORATE	:= DA0->DA0_HORATE
		ZGS->ZGS_CONDPG	:= DA0->DA0_CONDPG
		ZGS->ZGS_TPHORA	:= DA0->DA0_TPHORA
		ZGS->ZGS_ATIVO 	:= DA0->DA0_ATIVO
		ZGS->ZGS_CODPRO	:= DA1->DA1_CODPRO
		ZGS->ZGS_GRUPO 	:= DA1->DA1_GRUPO
		ZGS->ZGS_PRCVEN	:= DA1->DA1_PRCVEN
		ZGS->ZGS_I_PRCA	:= DA1->DA1_I_PRCA
		ZGS->ZGS_PRCMAX	:= DA1->DA1_PRCMAX
		ZGS->ZGS_I_PRMP	:= DA1->DA1_I_PRMP
		ZGS->ZGS_I_PTBN	:= DA1->DA1_I_PTBN
		ZGS->ZGS_I_VIGI	:= DA1->DA1_I_VIGI
		ZGS->ZGS_I_VIGF	:= DA1->DA1_I_VIGF
		ZGS->ZGS_ODATDE   := DA0->DA0_DATDE
		ZGS->ZGS_OHORAD   := DA0->DA0_HORADE
		ZGS->ZGS_ODATAT   := DA0->DA0_DATATE
		ZGS->ZGS_OHORAT   := DA0->DA0_HORATE
		ZGS->ZGS_OCONDP   := DA0->DA0_CONDPG
		ZGS->ZGS_OTPHOR   := DA0->DA0_TPHORA
		ZGS->ZGS_OATIVO   := DA0->DA0_ATIVO
		ZGS->ZGS_OCODPR   := DA1->DA1_CODPRO 
		ZGS->ZGS_OGRUPO   := DA1->DA1_GRUPO
		ZGS->ZGS_OPRCVE   := DA1->DA1_PRCVEN
		ZGS->ZGS_I_OPRC   := DA1->DA1_I_PRCA
		ZGS->ZGS_OPRCMA   := DA1->DA1_PRCMAX
		ZGS->ZGS_I_OPRM   := DA1->DA1_I_PRMP
		ZGS->ZGS_I_OPTB   := DA1->DA1_I_PTBN
		ZGS->ZGS_I_OVII   := DA1->DA1_I_VIGI
		ZGS->ZGS_I_OVIF   := DA1->DA1_I_VIGF
		ZGS->ZGS_STATUS   := "A"
		ZGS->(MSUnLock())

      DA1->(RecLock("DA1",.F.))
      DA1->DA1_PRCVEN := TRBDA1->WK_PRCVEN // "PR Carga Fech"
      DA1->DA1_I_PMFE := TRBDA1->WK_I_PMFE // "PR Min Carga Fech"
      DA1->DA1_I_PRFE := TRBDA1->WK_I_PRFE // "PR Carga Frac"
      DA1->DA1_I_PMFR := TRBDA1->WK_I_PMFR // "PR Min Carga Frac"
      DA1->DA1_I_PRCA := TRBDA1->WK_I_PRCA // "Preço Máximo" 
      DA1->DA1_PRCMAX := TRBDA1->WK_PRCMAX // "Preço Máximo" 
      DA1->(MSUnLock())        
      
      TRBDA1->(DBSkip())
      
      _nI += 1

   EndDo
   
   U_ITMsg("Dados gravados com sucesso!.","Atenção",,2)

End Sequence

Return 

/*
===============================================================================================================================
Programa--------: AOMS122E
Autor-----------: Julio de Paula Paz
Data da Criacao-: 24/03/2021
===============================================================================================================================
Descrição-------: Rotina de exportação de dados para o Excel.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================*/
User Function AOMS122E()
Local _aTitulos := {}
Local _aDados := {}

Begin Sequence 
   _aTitulos := {"Código Tab.Preço",;
                 "Descr.Tab.Preço",;
                 "Mix",;
                 "Grupo de Produto",;
                 "Código Protudo",;
                 "Descr.Produto",;
                 "PR Carga Fech",;
                 "Reaj.PR Carga Fech",;
                 "PR Min Carga Fech",;
                 "Reaj.PR Min Carga Fech",;
                 "PR Carga Frac",;
                 "Reaj.PR Carga Frac",;
                 "PR Min Carga Frac",;
                 "Reaj.PR Min Carga Frac",;
                 "Preco Maximo",;
                 "Reaj.Preco Maximo",;
                 "Preco Maximo",;
                 "Reaj.Preco Maximo"}
   
   TRBDA1->(DBGoTop())
   While ! TRBDA1->(Eof())
      If TRBDA1->DA1_FILIAL == '01' // Exibir os dados de apenas uma filial para o usuário.
         aAdd(_aDados,{ TRBDA1->DA1_CODTAB,;  // Código Tab.Preço
                        TRBDA1->DA1_DESTAB,;  // Descr.Tab.Preço
                        TRBDA1->DA1_I_MIX,;   // Mix
                        TRBDA1->DA1_GRUPO,;   // Grupo de Produto
                        TRBDA1->DA1_CODPRO,;  // Código Protudo
                        TRBDA1->DA1_DESCRI,;  // Descr.Produto
                        TRBDA1->DA1_PRCVEN,;  // PR Carga Fech"
                        TRBDA1->WK_PRCVEN,;   //  "Reaj.PR Carga Fech"
                        TRBDA1->DA1_I_PMFE,;  //  "PR Min Carga Fech"
                        TRBDA1->WK_I_PMFE,;   //  "Reaj.PR Min Carga Fech"
                        TRBDA1->DA1_I_PRFE,;  //  "PR Carga Frac"
                        TRBDA1->WK_I_PRFE,;   //  "Reaj.PR Carga Frac"
                        TRBDA1->DA1_I_PMFR,;  //  "PR Min Carga Frac"
                        TRBDA1->WK_I_PMFR,;   //  "Reaj.PR Min Carga Frac"
                        TRBDA1->DA1_I_PRCA,;  //  "Preco Maximo"
                        TRBDA1->WK_I_PRCA,;   //  "Reaj.Preco Maximo"
                        TRBDA1->DA1_PRCMAX,;  //  "Preco Maximo"
                        TRBDA1->WK_PRCMAX })  //  "Reaj.Preco Maximo"   
      EndIf
   
      TRBDA1->(DBSkip())
   EndDo 

   U_ITListBox( 'Exportação de dados - Ajustes de tabelas de preços - [' + _cTipoReajuste + "]" , _aTitulos , _aDados)

End Sequece

Return
