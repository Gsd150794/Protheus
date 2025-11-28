/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
===============================================================================================================================
Josué Danich      | 23/04/2019 | Ajuste de campos obrigatórios com valores zerados - Chamado 28909  
Jerry             | 12/07/2019 | Ajuste de campos Filial ao Gravar Ocorrencia por Ordem de Carga - Chamado 29959
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
==============================================================================================================================================================================================
Analista - Programador   - Inicio   - Envio    - Chamado - Motivo da Alteração
==============================================================================================================================================================================================
Alex     - Alex Wallauer - 16/01/24 - 20/03/25 -  49966  - CORREÇÃO DE ERROR.LOG: argument #0 error, expected N->U,function DBGoTo on U_AOMS072R(AOMS072.PRW) Line : 872
Jerry    - Alex Wallauer - 10/02/25 - 20/03/25 -  49042  - Ajustes para trartar notas ficais de Transferencia de troca nota. 
Jerry    - Alex Wallauer - 29/07/25 - 01/08/25 -  49733  - Criação e tratamento do novo campo ZF5_CAUCUS para informar o Causador do Custo.
Vandelei - Alex Wallauer - 16/05/25 - 02/09/25 -  50481  - Controle de entregas redirecionadas para operador logístico. 
Jerry    - Alex Wallauer - 15/08/25 - 02/09/25 -  51229  - Colocado o envio de email para o #comercial por nota e por ocorrencias de uma carga.
Jerry    - Alex Wallauer - 20/08/25 - 02/09/25 -  49733  - Colocado colunas novas no Browse de marca e desmarca das notas: F2_I_PENCL e C5_I_AGEND 
Jerry    - Alex Wallauer - 03/09/25 - 03/09/25 -  51229  - Inclusao das validações da data de ocorrrecia.
==============================================================================================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "Totvs.Ch"

/*
===============================================================================================================================
Programa--------: AOMS072
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/06/2016
===============================================================================================================================
Descrição-------: Inclusão múltipla de ocorrências de frete - Chamado 15564.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS072() As Logical
Local _bProcess As Block   
Local _lRet := .T. As Logical
Local _oModel := FWLoadModel( "AOMS003" ) As Object

Private _oProcesso

//Log de utilização
U_ITLOGACS()

Begin Sequence
   //================================================================================
   // _lUsaMVC  - Indica que esta subrotina não utiliza MVC.
   // _cNomeFonte - Nome do fonte ativo no momento.
   //================================================================================
   _lUsaMVC := .F.
   _cNomeFonte := "AOMS072"
        
   //================================================================================
   // Ativa o modelo de dados principal
   //================================================================================
   _oModel:Activate()                  
   
   //================================================================================
   // Cria tela principal com o dicinário de perguntas
   //================================================================================   
   _bProcess    := {|_oSelf| AOMS072P(_oSelf) }
   _oProcesso := TNewProcess():New( "AOMS072", "Gestão de Ocorrência de Cargas", _bProcess, "Rotina de gestão de ocorrência de cargas...","AOMS072",,,,,,.T.)
   
End Sequence

_lUsaMVC := .T.
_cNomeFonte := "AOMS003"

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS072C
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
===============================================================================================================================
Descrição---------: Gestão de Ocorrências de Frete - Chamado 15564.
                    Valida a digitação da tela de parâmetros inicias.
===============================================================================================================================
Parametros--------: _cCampo = campo ou rotina que chamou esta validação.
===============================================================================================================================
Retorno-----------: True ou False
===============================================================================================================================
*/
User Function AOMS072V(_cCampo)
Local _lRet := .T.
Local _aOrd := SaveOrd({"DAK"})

Begin Sequence 
   DAK->(DBSetOrder(1))
   
   If _cCampo == "MV_PAR01" .Or. _cCampo == "PROCESSAR"
      If Empty(MV_PAR01)
         U_ITMsg("O preenchimento do código da carga é obrigatório.","Atenção",,1)
         _lRet := .F.
         Break
      EndIf                           
               
      If ! DAK->(DBSeek(xFilial("DAK")+MV_PAR01))
         U_ITMsg("O código de carga informado não existe.","Atenção",,1)
         _lRet := .F.
         Break      
      EndIf                                               
      
   ElseIf _cCampo == "MV_PAR02" .Or. _cCampo == "PROCESSAR"
      If Empty(MV_PAR02)
         MV_PAR02:="01"
         //U_ITMsg("O preenchimento da sequência da carga é obrigatório.","Atenção",,1)
         //_lRet := .F.
         //Break
      EndIf
                               
      If ! DAK->(DBSeek(xFilial("DAK")+MV_PAR01+MV_PAR02))
         U_ITMsg("O código e sequência de carga informado não existe: "+MV_PAR01+MV_PAR02,"Atenção",,1)
         _lRet := .F.
         Break      
      EndIf
   EndIf
   
End Sequence

RestOrd(_aOrd)

Return _lRet

/*
===============================================================================================================================
Programa----------: AOMS072P
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
===============================================================================================================================
Descrição---------: Funcção principal da rotina Gestão de Ocorrências de Frete - Chamado 15564.                    
===============================================================================================================================
Parametros--------: _oSelf = Objeto da tela principal
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function AOMS072P(_oSelf)
Local _aCamposTab := {}
Local _lInverte := .F. 
Local _aButtons := {}, _lRet := .F.
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _aCores    
Local _nLin1,_nCol1, _nLin2, _nCol2

Private _aCampos := {}
Private _oMarkSelect, _oDlgSelect
Private _cMarcaSelct   := GetMark() 
Private _lMontaTela := .T.

Begin Sequence
   If ! U_AOMS072V("PROCESSAR")  
      U_ITMsg("Para iniciar o processamento, deve-se preencher corretamente a tela de perguntas","Atenção",,1)
      Break
   EndIf

   //================================================================================
   // Define as cores dos itens de legenda.
   //================================================================================      
   _aCores := {}
   aAdd(_aCores,{"TRBSF2->WK_STATUS == '0'","BR_VERDE"	})   
   aAdd(_aCores,{"TRBSF2->WK_STATUS == '1'","BR_VERMELHO"})

   _cTitulo := "Gestão de Ocorrências de Frete - Lista de Notas Fiscais - Carga: " +MV_PAR01+"-"+MV_PAR02
  
   //================================================================================
   // Cria tabela temporária.
   //================================================================================                                    
   aAdd(_aCamposTab,{"WK_OK"     ,"C",2		                ,0 })
   aAdd(_aCamposTab,{"F2_FILIAL" ,"C",TamSX3("F2_FILIAL")[1] ,0 })
   aAdd(_aCamposTab,{"F2_DOC"    ,"C",TamSX3("F2_DOC")[1]    ,0 })   
   aAdd(_aCamposTab,{"F2_SERIE"  ,"C",TamSX3("F2_SERIE")[1]  ,0 })
   aAdd(_aCamposTab,{"F2_CLIENTE","C",TamSX3("F2_CLIENTE")[1],0 })
   aAdd(_aCamposTab,{"F2_LOJA"   ,"C",TamSX3("F2_LOJA")[1]   ,0 })
   aAdd(_aCamposTab,{"A1_NOME"   ,"C",TamSX3("A1_NOME")[1]   ,0 })
   aAdd(_aCamposTab,{"WK_STATUS" ,"C",1                      ,0 })   
   aAdd(_aCamposTab,{"WK_RECNO"  ,"N",10                     ,0 })
   aAdd(_aCamposTab,{"F2_I_LOCEM","C",TamSX3("F2_I_LOCEM")[1],0 })
   aAdd(_aCamposTab,{"F2_I_REDP" ,"C",TamSX3("F2_I_REDP" )[1],0 })
   aAdd(_aCamposTab,{"F2_I_RELO" ,"C",TamSX3("F2_I_RELO" )[1],0 })
   aAdd(_aCamposTab,{"F2_I_OPER" ,"C",TamSX3("F2_I_OPER" )[1],0 })
   aAdd(_aCamposTab,{"F2_I_OPLO" ,"C",TamSX3("F2_I_OPLO" )[1],0 })
   aAdd(_aCamposTab,{"F2_I_PENCL","D",08,0})
   aAdd(_aCamposTab,{"C5_I_TRCNF","C",03,0})
   aAdd(_aCamposTab,{"C5_I_AGEND","C",30,0})
   aAdd(_aCamposTab,{"ZF5_MERENT","C",03,0})
   aAdd(_aCamposTab,{"WK_NFCARR" ,"C",Len(SF2->F2_FILIAL)+Len(SF2->F2_DOC)+Len(SF2->F2_SERIE)+2,0 })
   aAdd(_aCamposTab,{"WK_PEDCAR" ,"C",Len(SC5->C5_I_FILFT)+Len(SC5->C5_I_PDFT)+1,0 })   
   aAdd(_aCamposTab,{"WK_PEDFAT" ,"C",Len(SC5->C5_I_FLFNC)+Len(SC5->C5_I_PDPR)+1,0 })   
    //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
   //================================================================================
   If Select("TRBSF2") > 0
      TRBSF2->( DBCloseArea() )
   EndIf
    
   _otemp := FWTemporaryTable():New( "TRBSF2", _aCamposTab )

   _otemp:AddIndex( "01", {"F2_FILIAL","F2_DOC","F2_SERIE"} )

   _otemp:Create()
            
   //================================================================================
   // Carrega dados na tabela temporária.
   //================================================================================
   _lRet := U_AOMS072D(MV_PAR01,MV_PAR02,_oSelf)

   If ! _lRet
      U_ITMsg("NÃO existem notas para esta carga!",,,1)
      Break
   EndIf
   
   //================================================================================
   // Monta colunas do MsSelect()
   //================================================================================
                    //Campo       , "" , Titulo                                           , Picture   
   aAdd( _aCampos , { "WK_OK"		 ,    , " ",""})
   aAdd( _aCampos , { "F2_FILIAL" , "" , Getsx3cache("F2_FILIAL" ,"X3_TITULO"), Getsx3cache("F2_FILIAL" ,"X3_PICTURE")} ) 
   aAdd( _aCampos , { "F2_DOC"	 , "" , Getsx3cache("F2_DOC"    ,"X3_TITULO"), Getsx3cache("F2_DOC"    ,"X3_PICTURE")} )   
   aAdd( _aCampos , { "F2_SERIE"	 , "" , Getsx3cache("F2_SERIE"  ,"X3_TITULO"), Getsx3cache("F2_SERIE"  ,"X3_PICTURE")} )    
   aAdd( _aCampos , { "F2_CLIENTE", "" , Getsx3cache("F2_CLIENTE","X3_TITULO"), Getsx3cache("F2_CLIENTE","X3_PICTURE")} )
   aAdd( _aCampos , { "F2_LOJA"	 , "" , Getsx3cache("F2_LOJA"   ,"X3_TITULO"), Getsx3cache("F2_LOJA"   ,"X3_PICTURE")} )
   aAdd( _aCampos , { "A1_NOME"   , "" , Getsx3cache("A1_NOME"   ,"X3_TITULO"), Getsx3cache("A1_NOME"   ,"X3_PICTURE")} )
   aAdd( _aCampos , { "F2_I_LOCEM", "" , Getsx3cache("F2_I_LOCEM","X3_TITULO"), Getsx3cache("F2_I_LOCEM","X3_PICTURE")} )
   aAdd( _aCampos , { "C5_I_AGEND", "" , "Tipo de Entrega",""} ) 
   aAdd( _aCampos , { "F2_I_PENCL", "" , "Previsão de Entrega do Cliente",""} ) 
   aAdd( _aCampos , { "ZF5_MERENT", "" , "Mercadoria entregue?",""} ) 
   aAdd( _aCampos , { "F2_I_REDP" , "" , Getsx3cache("F2_I_REDP" ,"X3_TITULO"), Getsx3cache("F2_I_REDP" ,"X3_PICTURE")} )
   aAdd( _aCampos , { "F2_I_RELO" , "" , Getsx3cache("F2_I_RELO" ,"X3_TITULO"), Getsx3cache("F2_I_RELO" ,"X3_PICTURE")} )
   aAdd( _aCampos , { "F2_I_OPER" , "" , Getsx3cache("F2_I_OPER" ,"X3_TITULO"), Getsx3cache("F2_I_OPER" ,"X3_PICTURE")} )
   aAdd( _aCampos , { "F2_I_OPLO" , "" , Getsx3cache("F2_I_OPLO" ,"X3_TITULO"), Getsx3cache("F2_I_OPLO" ,"X3_PICTURE")} )
   aAdd( _aCampos , { "C5_I_TRCNF", "" , "Troca Nota?",""} ) 
   aAdd( _aCampos,  { "WK_NFCARR" , "" , "Nota de Carregamento"  ,"@!"} )
   aAdd( _aCampos,  { "WK_PEDCAR" , "" , "Pedido de Carregamento","@!"} )
   aAdd( _aCampos,  { "WK_PEDFAT" , "" , "Pedido de Faturamento" ,"@!"} )

   _bOk := {|| If(U_AOMS072O(),(_lRet := .T., _oDlgSelect:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgSelect:End()}

   TRBSF2->(DBGoTop())

   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   _nLin1 := 9
   _nCol1 := 0
   _nLin2 := _aSizeAut[6] * 0.079023  // 55
   _nCol2 := _aSizeAut[5] * 0.126138  // 194
   _lRet  := .F.//PQ SE APERTAR ESC OU O BOTÃO X DA TELA , DÁ ERRO LOG.//CORREÇÃO DE ERROR.LOG: argument #0 error, expected N->U,function DBGoTo on U_AOMS072R(AOMS072.PRW) Line : 872
   
   _aButtons:={}
   aAdd(_aButtons,{"",{|| U_AOMS072M("T") },"Marc/Des","Marca/Desmarca Todos"})
   aAdd(_aButtons,{"",{|| U_AOMS072L()    },"Legenda" ,"Legenda"})

   Define MsDialog _oDlgSelect Title _cTitulo From _nLin1,_nCol1 To _nLin2,_nCol2 Of oMainWnd 
              
      _oMarkSelect := MsSelect():New("TRBSF2","WK_OK","",_aCampos,@_lInverte, @_cMarcaSelct,{_aSizeAut[7]+20, 5, _aSizeAut[4], _aSizeAut[3]},,,,,_aCores)
      _oMarkSelect:bAval := {|| U_AOMS072M("P")}
      _lMontaTela := .F.
      _oDlgSelect:lMaximized:=.T.
 
   Activate MsDialog _oDlgSelect On Init (EnchoiceBar(_oDlgSelect,_bOk,_bCancel,,_aButtons), _oMarkSelect:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT , _oMarkSelect:oBrowse:Refresh() )
   
   If _lRet
      If U_AOMS072I()
         _oSelf:SaveLog( "REALIZADO A INCLUSÃO AUTOMÁTICA DE NOTAS FISCAIS POR CARGA NA GESTÃO DE OCORRÊNCIAS." )
      EndIf
   EndIf

End Sequence

If Select("TRBSF2") > 0
  TRBSF2->( DBCloseArea() )
EndIf

Return .F. //_lRet                          

/*
===============================================================================================================================
Programa----------: AOMS072L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/06/2016
===============================================================================================================================
Descrição---------: Rotina de exibição de legenda do MsSelect
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function AOMS072L()
Local _aLegenda := {}

Begin Sequence
   aAdd(_aLegenda,{"BR_VERDE"    ,"Nota Fiscal não cadastrada." })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Nota Fiscal já cadastrada." })

   BrwLegenda("Gestão de Ocorrências de Frete", "Legenda", _aLegenda)

End Sequence

Return

/*
===============================================================================================================================
Programa--------: AOMS072M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/06/2016
===============================================================================================================================
Descrição-------: Função para marcar e desmarcar todas as notas fiscais da carga.
===============================================================================================================================
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS072M(_cTipoMarca)
Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBSF2->(Recno()) 

Begin Sequence          
   If _lMontaTela
      Break
   EndIf
   If Empty(TRBSF2->WK_OK )
      _cSimboloMarca := _cMarcaSelct
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBSF2->WK_OK := _cSimboloMarca 
   Else
      TRBSF2->(DBGoTop())
      While ! TRBSF2->(Eof())
         TRBSF2->WK_OK := _cSimboloMarca 
         TRBSF2->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBSF2->(DBGoTo(_nRegAtu)) 
_oMarkSelect:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa--------: AOMS072D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/06/2016
===============================================================================================================================
Descrição-------: Carrega os dados das notas fiscais com base com base no codigo e sequência da carga.
===============================================================================================================================
Parametros------: _cCodCarga = Código da Carga
                  _cSeqCarga = Sequencia da Carga
                  _oself     = Objeto da tela principal
===============================================================================================================================
Retorno---------: True ou False
===============================================================================================================================
*/
User Function AOMS072D(_cCodCarga As String, _cSeqCarga As String, _oself As Object) As Logical
 Local _lRet := .T. As Logical
 Local _cQry As String
 Local _nTotreg As Numeric
 Local _cStatus As String
 Local _aOrd := SaveOrd({"ZF5"}) As Array
 Local _cAlias := GetNextAlias() As String 
 
 Begin Sequence
   //================================================================================
   // Monta e rota a query de seleção de dados
   //================================================================================   
   _cQry := " SELECT F2_FILIAL, F2_DOC, F2_SERIE, F2_CLIENTE, F2_LOJA, A1_NOME, SF2.R_E_C_N_O_ AS NRECNO "
   _cQry += " FROM "+RetSqlName("SF2")+" SF2, "+RetSqlName("SA1")+" SA1 " 
   _cQry += " WHERE SF2.D_E_L_E_T_ = ' ' AND SA1.D_E_L_E_T_ = ' ' "
   _cQry += " AND SF2.F2_FILIAL = '"+xFilial("SF2")+"' AND SA1.A1_FILIAL = '"+xFilial("SA1")+"' "
   _cQry += " AND SF2.F2_CLIENTE = SA1.A1_COD AND SF2.F2_LOJA = SA1.A1_LOJA "
   _cQry += " AND SF2.F2_CARGA = '"+_cCodCarga+"' AND SF2.F2_SEQCAR = '"+_cSeqCarga+"' "
   
   _cQry := ChangeQuery(_cQry) 
   MPSysOpenQuery( _cQry , _cAlias)

   If (_cAlias)->(Eof()) .Or. (_cAlias)->(Bof())
      _lRet := .F.
      Break
   EndIf   

   COUNT TO _nTotreg
   (_cAlias)->( DBGoTop() )
   
   _oself:SetRegua1( _nTotreg ) // Determina o tamanho da regua de processamento.   
   
   ZF5->(DBSetOrder(1))
   SF2->(DBSetOrder(1))
   
   While ! (_cAlias)->(Eof())      

      SF2->(DBGoTo((_cAlias)->NRECNO))
      _cWKNFCARR:=""
      _cWKPEDCAR:=""
      _cWKPEDFAT:=""
      _cChaveSF2:=(_cAlias)->F2_FILIAL+(_cAlias)->F2_DOC
      //QUANDO A NFE For DE TRANSFERÊNCIA, REFERENTE A TROCA NOTA, ALTERAR OS DADOS PARA NFE DE FATURAMENTO
      If (Posicione("SC5",,_cChaveSF2,"C5_I_TRCNF","IT_NOTA") = "S") 
         
         If SC5->C5_I_OPER = "20" //TRANSFERÊNCIA DA TROCA NOTA
            _cWKNFCARR:=SF2->F2_FILIAL+" "+SF2->F2_DOC+"-"+SF2->F2_SERIE // NOTA   DE CARREGAMENTO OK (COLUNA BROWSE)
            _cWKPEDCAR:=SF2->F2_FILIAL+" "+SF2->F2_I_PEDID               // PEDIDO DE CARREGAMENTO OK (COLUNA BROWSE)
            _cWKPEDFAT:=SC5->C5_I_FILFT+SC5->C5_I_PDFT                   // FILIAL + PEDIDO DE FATURAMENTO
            _cNotaFat :=Posicione("SC5",1,_cWKPEDFAT,"C5_NOTA")          // POSICIONADO NO SC5 P/ PEGAR A NOTA DE FATURAMENTO
            _cWKPEDFAT:=SC5->C5_I_FILFT+" "+SC5->C5_I_PDFT               // PEDIDO DE FATURAMENTO  OK (COLUNA BROWSE)
            _cChaveSF2:=SC5->C5_FILIAL+_cNotaFat+SC5->C5_SERIE           // FILAIL + NOTA + SERIE DE FATURAMENTO PARA POSICIONAR
            If !SF2->(DBSeek(_cChaveSF2))
               (_cAlias)->(DBSkip())
               Loop
            EndIf
         Else//FATURAMENTO DA TROCA NOTA
            _cWKPEDFAT:=SF2->F2_FILIAL+" "+SF2->F2_I_PEDID               // PEDIDO DE FATURAMENTO OK (COLUNA BROWSE)
            _cWKPEDCAR:=SC5->C5_I_FLFNC+SC5->C5_I_PDPR                   // FILIAL + PEDIDO DE CARREGAMENTO
            _cNotaCarr:=Posicione("SC5",1,_cWKPEDCAR,"C5_NOTA")          // POSICIONADO NO SC5 P/ PEGAR A NOTA DE CARREGAMENTO
            _cWKPEDCAR:=SC5->C5_I_FLFNC+" "+SC5->C5_I_PDPR               // PEDIDO DE CARREGAMENTO OK (COLUNA BROWSE)
            _cWKNFCARR:=SC5->C5_FILIAL+" "+_cNotaCarr+"-"+SC5->C5_SERIE  // NOTA DE CARREGAMENTO   OK (COLUNA BROWSE)
         EndIf
       
       EndIf

      _cStatus := '0' 
      If ZF5->(DBSeek(_cChaveSF2))
         _cStatus := '1'
      EndIf
                                     
      _oself:IncRegua1( "NOTA FISCAL: " + AllTrim(SF2->F2_FILIAL) + AllTrim(SF2->F2_DOC) + "-" +  AllTrim(SF2->F2_SERIE) )

      TRBSF2->(DBAPPEND())      
      TRBSF2->F2_FILIAL  := SF2->F2_FILIAL
      TRBSF2->F2_DOC     := SF2->F2_DOC 
      TRBSF2->F2_SERIE   := SF2->F2_SERIE 
      TRBSF2->F2_CLIENTE := SF2->F2_CLIENTE
      TRBSF2->F2_LOJA    := SF2->F2_LOJA 
      TRBSF2->A1_NOME    := (_cAlias)->A1_NOME
      TRBSF2->WK_STATUS  := _cStatus
      TRBSF2->WK_RECNO   := SF2->(RECNO())
      TRBSF2->F2_I_LOCEM := SF2->F2_I_LOCEM 
      TRBSF2->F2_I_REDP  := SF2->F2_I_REDP 
      TRBSF2->F2_I_RELO  := SF2->F2_I_RELO 
      TRBSF2->F2_I_OPER  := SF2->F2_I_OPER 
      TRBSF2->F2_I_OPLO  := SF2->F2_I_OPLO
      TRBSF2->F2_I_PENCL := SF2->F2_I_PENCL
      TRBSF2->C5_I_TRCNF := If(SC5->C5_I_TRCNF='S','SIM','NÃO')
      TRBSF2->WK_NFCARR  := _cWKNFCARR  
      TRBSF2->WK_PEDCAR  := _cWKPEDCAR
      TRBSF2->WK_PEDFAT  := _cWKPEDFAT 
      If !Empty(SC5->C5_I_AGEND)
         TRBSF2->C5_I_AGEND := SC5->C5_I_AGEND+"-"+U_TipoEntrega(SC5->C5_I_AGEND)
      EndIf
      If _cStatus = '1'
         TRBSF2->ZF5_MERENT := If(ZF5->ZF5_MERENT='S','SIM','NÃO')
      EndIf
                             
      (_cAlias)->(DBSkip())
   EndDo                
      
 End Sequence
 
 If Select((_cAlias)) > 0
    (_cAlias)->(DBCloseArea())
 EndIf
 
 RestOrd(_aOrd,.T.)

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072O
Autor-----------: Julio de Paula Paz
Data da Criacao-: 10/06/2016
===============================================================================================================================
Descrição-------: Valida se há dados selecionados para a inclusão automática de ocorrência de frete.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: True ou False
===============================================================================================================================
*/
User Function AOMS072O()
Local _lRet := .F.    
Local _nRegAtu := TRBSF2->(Recno())

Begin Sequence
   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())
      If ! Empty(TRBSF2->WK_OK)
         _lRet := .T.
         Exit
      EndIf
      TRBSF2->(DBSkip())
   EndDo     
   If ! _lRet 
      U_ITMsg("Não existem dados selecionados para inclusão de notas fiscais por carga.","Atenção",,1)        
   EndIf
End Sequence           

TRBSF2->(DBGoTo(_nRegAtu))

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072I
Autor-----------: Julio de Paula Paz
Data da Criacao-: 10/06/2016
===============================================================================================================================
Descrição-------: Valida se há dados selecionados para a inclusão automática de ocorrência de frete.
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno---------: True ou False
===============================================================================================================================
*/
User Function AOMS072I()
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo, _nReg := 3
Local _cCamposCapa   
Local _aObjects, _aPosObj, _aInfo, _oDlgEnch
Local _nOpcx := 3 // Inclusão  
Local _nUsado := 0, _nI
Local nX	:=0 
Local _nnj	:= 0

Private aHeader := {}, aRotina := {}, aCols := {}       
Private aTELA[0][0] // Variáveis que serão atualizadas pela Enchoice
Private aGETS[0]    // e utilizadas pela função OBRIGATORIO()
Private _nTotNf, _aCamposCapa := {} , _lRet := .F.

Begin Sequence
   //================================================================================
   // Define String com campos de capa para a tabela ZF5
   //================================================================================   
   _cTitulo := "Gestão de Ocorrências de Frete - Dados Base para Geração de Ocorrências - Carga: " +MV_PAR01+"-"+MV_PAR02
   _cCamposCapa := 'ZF5_FILIAL;'
   _cCamposCapa += 'ZF5_DOCOC;' 
   _cCamposCapa += 'ZF5_SEROC;'
   _cCamposCapa += 'ZF5_REPRES;'
   _cCamposCapa += 'ZF5_DATAE;'
   _cCamposCapa += 'ZF5_VLRFRE;'
   _cCamposCapa += 'ZF5_AGENDA;'
   _cCamposCapa += 'ZF5_VOLUM;'
   _cCamposCapa += 'ZF5_PEDIDO;' 
   _cCamposCapa += 'ZF5_TIPOV;'
   _cCamposCapa += 'ZF5_COORD;'
   _cCamposCapa += 'ZF5_NCOOR;'
   _cCamposCapa += 'ZF5_CLIENT;'
   _cCamposCapa += 'ZF5_NREPRE;'
   _cCamposCapa += 'ZF5_PESON;'
   _cCamposCapa += 'ZF5_LOJA;'
   _cCamposCapa += 'ZF5_NCLIEN;'
   _cCamposCapa += 'ZF5_UF;'
   _cCamposCapa += 'ZF5_CIDADE;'
   _cCamposCapa += 'ZF5_TRANSP;'
   _cCamposCapa += 'ZF5_LJTRAN;'
   _cCamposCapa += 'ZF5_NTRANS;'
   _cCamposCapa += 'ZF5_SEQCAR;'
   _cCamposCapa += 'ZF5_CARGA;'
   _cCamposCapa += 'ZF5_MOTORI;'
   _cCamposCapa += 'ZF5_DMOTOR;'
   _cCamposCapa += 'ZF5_VEICUL;'
   _cCamposCapa += 'ZF5_DVEICU;'
   _cCamposCapa += 'ZF5_DTCAR;'
   _cCamposCapa += 'ZF5_PESO;'
   _cCamposCapa += 'ZF5_DATAL;'
   _cCamposCapa += 'ZF5_HORAL;'
   _cCamposCapa += 'ZF5_DATAC;'
   _cCamposCapa += 'ZF5_HORAC;'
   _cCamposCapa += 'ZF5_RPCOM;'
   _cCamposCapa += 'ZF5_RPLOGI;'
   _cCamposCapa += 'ZF5_NRPCO;'
   _cCamposCapa += 'ZF5_NRPLO;'
   _cCamposCapa += 'ZF5_OBSFR;'
   _cCamposCapa += 'ZF5_POSTOF;'
   _cCamposCapa += 'ZF5_TELEFO;'
   _cCamposCapa += 'ZF5_DAE;'
   _cCamposCapa += 'ZF5_VALORI;'
   _cCamposCapa += 'ZF5_SENHAM;'
   _cCamposCapa += 'ZF5_OBSPF;' 
   _cCamposCapa += 'ZF5_PLACA;'
   _cCamposCapa += 'ZF5_DATAS;'
   _cCamposCapa += 'ZF5_HORAS;'
 
   //================================================================================
   // Define um aRotina Genérico apenas para utilização da função MsGetDados. 
   // Para utilizar esta função é necessário definir um array aRotina.
   //================================================================================
   aRotina := {}
   aAdd(aRotina,{ "Pesquisar"    ,"AxPesqui"                , 0, 1})
   aAdd(aRotina,{ "Visualizar"   ,"AxVisual"                , 0, 2})
   aAdd(aRotina,{ "Incluir"      ,"AxInclui"                , 0, 3})
   aAdd(aRotina,{ "Alterar"      ,"AxAltera"                , 0, 4})
   aAdd(aRotina,{ "Excluir"      ,"AxDeleta"                , 0, 5})

   //================================================================================
   // Este array define os campos que poderão ser exibidos na tela principal definido
   // com a função MsGetDados.
   //================================================================================                                  
   aAdd(_aCamposCapa,"NOUSER")//Tem que tirar os campos de usuario pq todos são de usuarios que vão para os itens

   //================================================================================
   // Cria tabela temporária.
   //================================================================================
   _aZF5 := ZF5->(Dbstruct())
   _aorder := {}

   For nX := 1 To Len(_aZF5)
       aAdd( _aZF5[nx] , Getsx3cache(_aZF5[nX][1],"X3_ORDEM") )
   Next

   _aZF5 := aSort(_aZF5,,, {|x,y| x[5] < y[5] })
   
   For _nnj := 1 to Len(_aZF5)
       If _aZF5[_nnj][1] == "ZF5_MERENT"//Esse campo foi retirado para não soberpor o conteudo do campo ZF5_MERENT das notas fiscais já cadastradas.
          Loop
       EndIf

       &("M->"+AllTrim(_aZF5[_nnj][1])) := CriaVar(AllTrim(_aZF5[_nnj][1]))

       If AllTrim(_aZF5[_nnj][1]) $ _cCamposCapa  // Campos de capa
          aAdd(_aCamposCapa,AllTrim(_aZF5[_nnj][1]))
       Else
          _nUsado += 1
          aAdd( aHeader, { trim(getsx3cache(_aZF5[_NNJ][1],"X3_TITULO") ),;
                     getsx3cache(_aZF5[_NNJ][1],"X3_CAMPO")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_PICTURE")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_TAMANHO")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_DECIMAL")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_VALID")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_USADO")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_TIPO")			,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_ARQUIVO")		,;
                     getsx3cache(_aZF5[_NNJ][1],"X3_CONTEXT")	})
       EndIf
   Next
 
   aAdd(aCols,Array(_nUsado+1))

   For _nI := 1 To _nUsado    
       aCols[1][_nI] := CriaVar(aHeader[_nI][2])
   Next
   aCols[1][_nUsado+1] := .F.

   //================================================================================
   // Carrega dados na tabela temporária da primeira nota fiscal marcada
   //================================================================================
   If !U_AOMS072R("DIGITACAO")
      BREAK
   EndIf
                                                                                                                                                    
   //================================================================================
   // Tela de Manutenção
   //================================================================================
   _aObjects := {} 
   aAdd( _aObjects, { 100, 100, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 
   
   _bOk := {|| If(U_AOMS072E("GRAVACAO"),(_lRet := .T., _oDlgEnch:End()),)}
   _bCancel := {|| _lRet := .F., _oDlgEnch:End()}
   _nTotNf := 0  // Numero total de notas fiscais selecionadas pelo usuário.
   
   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
      
      EnChoice( "ZF5" ,_nReg, _nOpcx, , , , _aCamposCapa, _aPosObj[1], , 3 )
            
      _oGetDados := MsGetDados():New(_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4], 4, /*"U_LINHAOK"*/,  , "+ZF5_CODIGO", .T., /*{"A1_NOME"}*/, , .F., 200, /*"U_FIELDOK"*/, /*"U_SUPERDEL"*/, , /*"U_DELOK"*/, _oDlgEnch)
   
   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 
   
   If _lRet   
      U_ITMsg("Inclusão de ocorrências de frete por carga realizada com sucesso!","Atenção",,2)
   EndIf
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072E
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/06/2016
===============================================================================================================================
Descrição-------: Valida a digitação de dados na tela para geração de ocorrências por Carga.
===============================================================================================================================
Parametros------: _cChamada = Campo ou rotina que chamou a validação.
===============================================================================================================================
Retorno---------: True ou False
===============================================================================================================================
*/
User Function AOMS072E(_cChamada)
 Local _lCustoPreenchido := .T.
 Local _cCodFor, _cLojaFor, _cNomeFor, _nCustoTer
 Local _aOrd := SaveOrd({"SA2","SF2","SC5"})
 Local _cForPadrao := U_ITGETMV( 'IT_FORTERCE' , 'F046200020' ) // Como default deste parâmetro está o Fornecedor terceiro: Codigo: F04620 - Loja: 0020 - Nome: CASTROLANDA COOP AGROINDUSTRIA
 Local _cNumNf, _cSerieNf
 Local _nVlCobradoTon, _nPeso, _cCarga, _nI
 Local _lNF_OK
 Local _nFORTER:=0 As Numeric // Posição do campo Fornecedor Terceiros
 Local _nLOJTER:=0 As Numeric // Posição do campo Loja Terceiros
 Local _nNOMTER:=0 As Numeric // Posição do campo Nome Terceiros
 Local _nCUSTO :=0 As Numeric // Posição do campo Custo Total


 Private _lxRet := .T.
 
 Begin Sequence 
    //================================================================================
    // Pega a posição dos campos dentro do aCols
    //================================================================================
    For _nI := 1 To Len(aHeader)  
        If AllTrim(aHeader[_nI,2]) == "ZF5_FORTER"
           _nFORTER := _nI // Fornecedor Terceiros
        ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_LOJTER"
           _nLOJTER := _nI // Loja Terceiros
        ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_NOMTER"
           _nNOMTER := _nI // Nome Terceiros
        ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTO"
           _nCUSTO := _nI // CUSTO TOTAL
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOR"
        //   _nCUSTOR := _nI // CUSTO REPRESENTANTE
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOC"
        //   _nCUSTOC := _nI // CUSTO CLIENTE  
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTER"
        //   _nCUSTER := _nI // custo Terceiros  
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOT"
        //   _nCUSTOT := _nI // custo Terceiros      
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_TIPO"
        //   _nCUSTIP := _nI // tipo  
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_TIPOC"
        //   _nCUSTIC := _nI // tipo  
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_MOTCUS"
        //   _nCUSMOT := _nI // tipo  
        //ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_STATUS"
        //   _nPosStatus := _nI // tipo      
        EndIf
    Next          
    
    //================================================================================
    // Inicia as validações
    //================================================================================
    If _cChamada == "GRAVACAO"
       If !Obrigatorio(aGets,aTela) // Valida a digitação de dados na tela principal
          U_ITMsg("É necessário informar o conteúdo de todos os campos obrigatorios antes da gravação das ocorrências.","Atenção",,1)
          _lxRet := .F.
          Break
       EndIf
       _lNF_OK := .F.
       
       TRBSF2->(DBGoTop())
       While ! TRBSF2->(Eof())
          If ! Empty(TRBSF2->WK_OK)
             _nTotNf += 1
             If TRBSF2->(F2_FILIAL+F2_DOC + F2_SERIE) == M->ZF5_FILIAL + M->ZF5_DOCOC + M->ZF5_SEROC
                _lNF_OK := .T.               
             EndIf             
          EndIf
          
          TRBSF2->(DBSkip())                     
       EndDo
       
       If ! _lNF_OK
          U_ITMsg("A nota fiscal "+M->ZF5_FILIAL+" - "+M->ZF5_DOCOC+" - "+M->ZF5_SEROC+" não faz parte das notas fiscais selecionadas para inclusão de ocorrencias.", "Atenção",,1)
          _lxRet := .F.
       EndIf
       
       If _lxRet
          _lxRet := U_AOMS072Q() // VALIDACAO DO OK FINAL DA TELA 
       EndIf
       Break//*** SAIDA ******************************************************************************

     EndIf
 
    //*************** QUANDO A FUNÇÃO CHAMADA DOS VALIDS DOS CAMPOS *****************
    If _cChamada == 'ZF5_OLRCOD'
       nPosTIPOO := aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_TIPOO" })
       nPosOLRLOJ:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_OLRLOJ"})
       nPosOLRNOM:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_OLRNOM"})
       ZFC->(DBSetOrder(1))
       ZFC->(DBSeek(xFilial("ZFC")+aCols[N,nPosTIPOO]))
       If !Empty(M->ZF5_OLRCOD)
          If ZFC->ZFC_OLREDI  <> "S"
             U_ITMsg('Tipo de ocorrecia não é de redirecionamento. (ZFC_OLREDI<>"S").','Atenção',;
                     'O Codigo do operador logistico do redirecionamento não pode ser informado.',,,,.T.)
             _lxRet := .F.
             aCols[N,nPosOLRLOJ] := Space(Len(ZF5->ZF5_OLRLOJ))
             aCols[N,nPosOLRNOM] := Space(Len(ZF5->ZF5_OLRNOM))
          ElseIf SA2->(DBSeek(xFilial("SA2")+M->ZF5_OLRCOD)) 
             aCols[N,nPosOLRLOJ] := SA2->A2_LOJA
             aCols[N,nPosOLRNOM] := SA2->A2_NOME
          Else
             U_ITMsg("Código de Transportadora não cadastrado  no cadastro de fornecedores.","Atenção",,,,,.T.)
             _lxRet := .F.
          EndIf
       Else
          If ZFC->ZFC_OLREDI == "S"
             U_ITMsg('Tipo de ocorrecia é de redirecionamento. (ZFC_OLREDI="S").','Atenção',;
                     "Informe o Codigo+loja do operador logistico do redirecionamento.",,,,.T.)
             _lxRet := .F.
          Else
             aCols[N,nPosOLRLOJ] := Space(Len(ZF5->ZF5_OLRLOJ))
             aCols[N,nPosOLRNOM] := Space(Len(ZF5->ZF5_OLRNOM))
          EndIf
       EndIf
       Break//*** SAIDA ******************************************************************************
   
    ElseIf _cChamada == 'ZF5_OLRLOJ'
       nPosOLRCOD:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_OLRCOD"})
       nPosOLRNOM:= aScan(aHeader,{|x| AllTrim(x[2]) == "ZF5_OLRNOM"})
       If !Empty(aCols[N,nPosOLRCOD]) .Or. !Empty(M->ZF5_OLRLOJ)
          If SA2->(DBSeek(xFilial("SA2")+aCols[N,nPosOLRCOD]+M->ZF5_OLRLOJ))
             aCols[N,nPosOLRNOM] := LEFT(SA2->A2_NOME,Len(ZF5->ZF5_OLRNOM) )
          Else
             U_ITMsg("Código+loja de Transportadora não cadastrado no cadastro de fornecedores.","Atenção",,,,,.T.)
             _lxRet := .F.
          EndIf
       Else//Se os 2 em branco, limpa
          aCols[N,nPosOLRNOM] :=  Space(Len(ZF5->ZF5_OLRNOM))
       EndIf
       Break//*** SAIDA ******************************************************************************
   
    EndIf

    _nCustoTer := M->ZF5_CUSTER // aCols[N,27]   
        
    If Empty(_nCustoTer)
       _lCustoPreenchido := .F.
    EndIf
  
    _cCodFor  := M->ZF5_FORTER // aCols[N,28] 
    _cLojaFor := M->ZF5_LOJTER // aCols[N,29] 
    _cNomeFor := M->ZF5_NOMTER // aCols[N,30]  
    
    SA2->(DBSetOrder(1))
    SF2->(DBSetOrder(1))
    SC5->(DBSetOrder(1))  
 
    If _cChamada == 'ZF5_CUSTER'
       
       If Empty(_nCustoTer)                
          aCols[N,_nFORTER] := Space(6)  // ZF5_FORTER
          aCols[N,_nLOJTER] := Space(4)  // ZF5_LOJTER
          aCols[N,_nNOMTER] := Space(40) // ZF5_NOMTER 
       ElseIf Empty(_cCodFor)       
          SA2->(DBSeek(xFilial("SA2")+_cForPadrao))
          aCols[N,_nFORTER] := SA2->A2_COD   // ZF5_FORTER
          aCols[N,_nLOJTER] := SA2->A2_LOJA  // ZF5_LOJTER
          aCols[N,_nNOMTER] := SA2->A2_NOME  // ZF5_NOMTER 
       EndIf 
       
    ElseIf _cChamada == 'ZF5_FORTER'
       
       If ! _lCustoPreenchido .And. ! Empty(_cCodFor)
          U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
          _lxRet := .F.
          Break
       EndIf
       
       If _lCustoPreenchido 
          If ! SA2->(DBSeek(xFilial("SA2")+_cCodFor))
             U_ITMsg("Código de Terceiro não cadastrado no cadastro de fornecedores.","Atenção",,1)
             _lxRet := .F.
             Break
          Else   
             aCols[N,_nLOJTER] := SA2->A2_LOJA  // ZF5_LOJTER
             aCols[N,_nNOMTER] := SA2->A2_NOME  // ZF5_NOMTER 
          EndIf
       EndIf
       
    ElseIf _cChamada == 'ZF5_LOJTER'
       
       If ! _lCustoPreenchido .And. ! Empty(_cLojaFor)
          U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
          _lxRet := .F.
          Break
       EndIf
       
       If _lCustoPreenchido 
          If ! SA2->(DBSeek(xFilial("SA2")+_cCodFor+_cLojaFor))
             U_ITMsg("Código+Loja de Terceiro não cadastrado no cadastro de fornecedores.","Atenção",,1)
             _lxRet := .F.
             Break
          Else
             aCols[N,_nNOMTER] := SA2->A2_NOME  // ZF5_NOMTER 
          EndIf
       EndIf
       
    ElseIf _cChamada == 'ZF5_NOMTER'
       
       If ! _lCustoPreenchido .And. ! Empty(_cNomeFor)
          U_ITMsg("O campo custo de terceiro precisa ser preenchido.","Atenção",,1)
          _lxRet := .F.
          Break
       EndIf
       
    ElseIf _cChamada == 'ZF5_AGENDA'
       
       _cNumNf   := M->ZF5_DOCOC
       _cSerieNf := M->ZF5_SEROC      
       SF2->(DBSeek(xFilial("SF2")+_cNumNf))
       SC5->(DBSeek(SF2->(F2_FILIAL+F2_I_PEDID)))
       M->ZF5_AGENDA := AllTrim(SC5->C5_MENNOTA)        
                                      
       
    ElseIf _cChamada == 'ZF5_VALTON'        
       _nVlCobradoTon := 0  
       _cCarga := Posicione("SF2",1,xFilial("SF2")+AllTrim(M->ZF5_DOCOC),"F2_CARGA") 
       _nPeso  := Posicione("DAK",1,xFilial("ZF5")+AllTrim(_cCarga),"DAK_PESO") 
       _nCusto := aCols[N,_nCUSTO] // ZF5_CUSTO
       
       _nVlCobradoTon  += (_nCusto / (_nPeso / 1000))
       _lxRet := _nVlCobradoTon
           
    EndIf  
 
 End Sequence
 
 If _cChamada == "GRAVACAO" .And. _lxRet .And. U_ITMsg("Confirma a inclusão das ocorrências de frete, para TODAS AS NOTAS fiscais selecionadas?", "Atenção",,2,2,2)
    FWMsgRun(,{|oproc| _lxRet := U_AOMS072G(oproc) },'Aguarde processamento...','Gravando dados...')
 ElseIf _cChamada == "GRAVACAO"
    _lxRet := .F.   
 EndIf
 
 RestOrd(_aOrd)

Return _lxRet

/*
===============================================================================================================================
Programa--------: AOMS072R
Autor-----------: Julio de Paula Paz
Data da Criacao-: 13/06/2016
===============================================================================================================================
Descrição-------: Carrega os dados da primeira nota fiscal e disponibiliza para o usuário fazer manutenção.
===============================================================================================================================
Parametros------: _cChamada = Rotina que chamou esta função.
===============================================================================================================================
Retorno---------: _lRet
===============================================================================================================================
*/
User Function AOMS072R(_cChamada As String) As Logical
Local _lRet := .F. As Logical
Local _nRegNf := 0 As Numeric
Local _cret As String, _cret3 As String, _cret4 As String

Begin Sequence         
   If _cChamada == "DIGITACAO"
      TRBSF2->(DBGoTop())
      _nRegNf :=TRBSF2->WK_RECNO
      While ! TRBSF2->(Eof())
         If ! Empty(TRBSF2->WK_OK)
            _nRegNf := TRBSF2->WK_RECNO
            Exit
         EndIf
      
         TRBSF2->(DBSkip())
      EndDo
      If _nRegNf > 0   
         SF2->(DBGoTo(_nRegNf))
      Else
         BREAK // Se não encontrou nenhuma nota fiscal selecionada, sai da função.
      EndIf
   EndIf 
   _lRet:=.T.
   //_cChamada == #GRAVACAO
   M->ZF5_FILIAL := SF2->F2_FILIAL
   M->ZF5_DOCOC  := SF2->F2_DOC    
   M->ZF5_SEROC  := SF2->F2_SERIE  
   M->ZF5_CARGA  := SF2->F2_CARGA
   M->ZF5_SEQCAR := SF2->F2_SEQCAR                                
   
   SC5->(DBSeek(SF2->(F2_FILIAL+F2_I_PEDID)))
   M->ZF5_AGENDA := AllTrim(SC5->C5_MENNOTA)  
   M->ZF5_DATAE :=  SC5->C5_I_DTENT     

   If ! Empty(SF2->F2_CARGA)    
      DAK->(DBSetOrder(1))
      DAK->(DBSeek(SF2->F2_FILIAL+SF2->F2_CARGA))

      DA4->(DBSetOrder(1))         
      DA4->(DBSeek(xFilial("DA4")+DAK->DAK_MOTORI))  
    
      DA3->(DBSetOrder(1))         
      DA3->(DBSeek(xFilial("DA3")+DAK->DAK_CAMINH))  

      M->ZF5_MOTORI := DAK->DAK_MOTORI
      M->ZF5_TIPOV := DA3->DA3_I_TPVC
     
     _cret3 := DA4->DA4_TEL
   
     If Val(_cret3) > 0
        If Len(_cret3) == 11
            _cret += " - " + Transform(Val(_cret3),"@R (99) 99999-9999")
         ElseIf Len(_cret3) == 10
            _cret += " - " + Transform(Val(_cret3),"@R (99) 9999-9999")
         EndIf
      EndIf
      M->ZF5_DMOTOR := DA4->DA4_NOME
      M->ZF5_VEICUL := DAK->DAK_CAMINH
      M->ZF5_DVEICU := DA3->DA3_DESC   
      M->ZF5_PLACA  := DA3->DA3_PLACA	  
      M->ZF5_DTCAR  := DAK->DAK_DATA
      M->ZF5_PESO   := DAK->DAK_PESO
   EndIf 
 
   If ! Empty(SF2->F2_VEND1)
      SA3->(DBSetOrder(1))         
      SA3->(DBSeek(xFilial("SA3")+SF2->F2_VEND1))  
        
     _cret  := SubStr(AllTrim(SA3->A3_NOME),1,30)
     _cret3 := SA3->A3_TEL
     _cret4 := SA3->A3_DDDTEL
   
     If Val(_cret3) > 0
        If Len(_cret3) == 9
          _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  99999-9999")
        ElseIf Len(_cret3) == 8
          _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  9999-9999")
         EndIf
      EndIf                          
      
      M->ZF5_REPRES := SF2->F2_VEND1    
      M->ZF5_NREPRE := _cret 
   EndIf	

   If !Empty(SF2->F2_VEND2)

      SA3->(DBSetOrder(1))         
      SA3->(DBSeek(xFilial("SA3")+SF2->F2_VEND2))
      
      _cret  := SubStr(AllTrim(SA3->A3_NOME),1,30)
      _cret3 := SA3->A3_TEL
      _cret4 := SA3->A3_DDDTEL
    
      If Val(_cret3) > 0
         If Len(_cret3) == 9
           _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  99999-9999")
         ElseIf Len(_cret3) == 8
           _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  9999-9999")
         EndIf
      EndIf	
      M->ZF5_COORD := SF2->F2_VEND2
      M->ZF5_NCOOR := _cret
   EndIf 

   If !Empty(SF2->F2_CLIENTE)   
      SA1->(DBSetOrder(1))
      SA1->(DBSeek(xFilial("SA1") + SF2->F2_CLIENTE + SF2->F2_LOJA))
      
      _cret  := SubStr(SA1->A1_NREDUZ,1,30) 
      _cret3 := AllTrim(SA1->A1_TEL)
      _cret4 := AllTrim(SA1->A1_DDD)
   
      If Val(_cret3) > 0
         If Len(_cret3) == 9
           _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  99999-9999")
         ElseIf Len(_cret3) == 8
           _cret += " - (" + _cret4 + ") " + Transform(Val(_cret3),"@R  9999-9999")
         EndIf
      EndIf  
      M->ZF5_CIDADE := SA1->A1_MUN
      M->ZF5_CLIENT := SF2->F2_CLIENTE   		
      M->ZF5_LOJA   := SF2->F2_LOJA
      M->ZF5_NCLIEN := _cret
   EndIf	

   If !Empty(SF2->F2_EST)
      M->ZF5_UF := SF2->F2_EST
   EndIf

   If Empty(SF2->F2_CARGA) //SE TIVER CARGA PEGA DA CARGA SENÃO DO SF2
      M->ZF5_TRANSP := SF2->F2_I_CTRA
      M->ZF5_LJTRAN := SF2->F2_I_LTRA
      M->ZF5_NTRANS := Posicione("SA2",1,xFilial("SA2")+SF2->F2_TRANSP+SF2->F2_I_LTRA,"A2_NOME")
   Else
      M->ZF5_TRANSP := DA4->DA4_FORNEC
      M->ZF5_LJTRAN := DA4->DA4_LOJA
      M->ZF5_NTRANS := Posicione("SA2",1,xFilial("SA2")+DA4->DA4_FORNEC+DA4->DA4_LOJA,"A2_NOME")
   EndIf

   M->ZF5_PESON := SF2->F2_PBRUTO

   If ! Empty(SF2->F2_VOLUME1)
      _cret := Transform(SF2->F2_VOLUME1,"@E 999,999")
      _cret += "  " + AllTrim(SF2->F2_ESPECI1) 
      M->ZF5_VOLUM := _cret
   EndIf

   M->ZF5_VLRFRE := SF2->F2_I_FRET		
   
   If !Empty(SF2->F2_I_PEDID)
      M->ZF5_PEDIDO := 	SF2->F2_I_PEDID
   EndIf
      
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072G
Autor-----------: Julio de Paula Paz
Data da Criacao-: 14/06/2016
===============================================================================================================================
Descrição-------: Replica e grava os dados digitados das ocorrências de frete, para cada nota fiscal selecionada.
===============================================================================================================================
Parametros------: oproc
===============================================================================================================================
Retorno---------: Nenhum
===============================================================================================================================
*/
User Function AOMS072G(oproc)
Local _lRet := .F.
Local _nI, _nJ
Local _nPercNf 
Local _nSeqCod

Begin Sequence

   DBSelectArea("TRBSF2")
    _nTot:=nConta:=0
    COUNT TO _nTot
    _cTot:=AllTrim(Str(_nTot))

    _cMensNF:=""
    _nTipo  :=2
    _lEmail := .F.

   TRBSF2->(DBGoTop())
   While ! TRBSF2->(Eof())

      nConta++

      If Empty(TRBSF2->WK_OK)
         TRBSF2->(DBSkip())
         Loop
      EndIf
      _lRet := .T.
      oProc:cCaption := ("Gravando NF: "+SF2->F2_DOC+" - "+StrZero(nConta,5) +" de "+ _cTot )
      ProcessMessages()

      SF2->(DBGoTo(TRBSF2->WK_RECNO))   
      
      _nSeqCod := U_AOMS072S(SF2->F2_FILIAL, SF2->F2_DOC, SF2->F2_SERIE)
      
      U_AOMS072R("#GRAVACAO") // CARREGA AS VARIAVEIS DE MEMORIA (M->) PARA CADA NOTA FISCAL (SF2) POSICIONADA.
                   
      _nPercNf := 100 / _nTotNf /100
      _aDadosEmailCom := {} // Array para armazenar os dados de email do #comercial

      For _nI := 1 To Len(aCols)
          
          ZF5->(RecLock("ZF5",.T.))
          ZF5->ZF5_FILIAL := M->ZF5_FILIAL//xFilial("ZF5")
          
          For _nJ := 1 To Len(_aCamposCapa)           
              If AllTrim(_aCamposCapa[_nJ]) == "NOUSER"
                 Loop
              EndIf
              &("ZF5->"+AllTrim(_aCamposCapa[_nJ])) := &("M->"+AllTrim(_aCamposCapa[_nJ]))
          Next
                 
          For _nJ := 1 To Len(aHeader)     
              If AllTrim(aHeader[_nJ,2]) $ "ZF5_CUSTO/ZF5_CUSTOC/ZF5_CUSTOI/ZF5_CUSTOR/ZF5_CUSTOT"
                // &("ZF5->"+AllTrim(aHeader[_nJ,2])) := aCols[_nI,_nJ] * _nPercNf
                 &("ZF5->"+AllTrim(aHeader[_nJ,2])) := aCols[_nI,_nJ]
              Else
                 &("ZF5->"+AllTrim(aHeader[_nJ,2])) := aCols[_nI,_nJ]
              EndIf
             
          Next  
          
          ZF5->ZF5_CODIGO := StrZero(_nSeqCod,6) // U_AOMS003k()           
          _nSeqCod += 1
          ZF5->(MSUnLock())

          If (ZF5->ZF5_STATUS == '000006'.AND. Posicione("ZFC",1,xFilial("ZFC")+ZF5->ZF5_TIPOO,"ZFC_ENVREP") = "S")
             _lEmail := .T. //ENVIA WF AO #comercial
             _aOcorreIt:= {}
             aAdd(_aOcorreIt,ZF5->ZF5_DTOCOR)//01
             aAdd(_aOcorreIt,ZF5->ZF5_CODIGO)//02
             aAdd(_aOcorreIt,ZF5->ZF5_MOTIVO)//03
             aAdd(_aOcorreIt,ZF5->ZF5_MOTCUS)//04
             aAdd(_aOcorreIt,ZF5->ZF5_TIPOO )//05
             aAdd(_aOcorreIt,ZF5->ZF5_TRANSP)//06
             aAdd(_aOcorreIt,ZF5->ZF5_LJTRAN)//07
             aAdd(_aOcorreIt,ZF5->ZF5_NTRANS)//08
             aAdd(_aDadosEmailCom,_aOcorreIt)
          EndIf

      Next

      oProc:cCaption := ("Gravando NF: "+SF2->F2_DOC+" - "+StrZero(nConta,5) +" de "+ _cTot+", Calculo de Datas..." )
      ProcessMessages()

      _aREcZF5:={}
      ZF5->(DBSetOrder(1))
      If ZF5->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
         While ZF5->(!Eof()) .And. SF2->F2_FILIAL == ZF5->ZF5_FILIAL;
                                .And. SF2->F2_DOC    == ZF5->ZF5_DOCOC;
                                .And. SF2->F2_SERIE  == ZF5->ZF5_SEROC
           aAdd(_aREcZF5,ZF5->(RECNO()))
           ZF5->(DBSkip())
           EndDo  
      EndIf

      U_AOMS3DTSF2("AOMS072",_aREcZF5)//FUNÇÃO CHAMADA NO AOMS003/74 TB E ESTA NO AOMS003.PRW

      If _lEmail //ENVIA WF AO #comercial
         _cMensagem:=""
         ZF5->(DBSeek(SF2->F2_FILIAL+SF2->F2_DOC+SF2->F2_SERIE))
         For _nI := 1 TO Len(_aDadosEmailCom)
             U_AOMS3Comercial(_aDadosEmailCom[_nI])
         Next _nI
         _lEmail := .F.
         _cMensNF+="NF: "+AllTrim(SF2->F2_DOC)+"-"+AllTrim(SF2->F2_SERIE) + CRLF + _cMensagem
      EndIf

      TRBSF2->(DBSkip())
   EndDo
    
   If Len(_aDadosEmailCom) > 0
      U_ITMsgLog(_cMensNF, "RESULTADO DOS ENVIOS DOS E-MAILs",1,.F.)
      //U_ITMsg(_cMensNF,"Envio do E-MAIL",,_nTipo)
   EndIf    
   
End Sequence

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072Q
Autor-----------: Julio de Paula Paz
Data da Criacao-: 28/07/2016
===============================================================================================================================
Descrição-------: Realiza as validações no aCols/dados de detalhe.  VALIDACAO DO OK FINAL DA TELA 
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
Retorno   ------: True ou False.
===============================================================================================================================
*/
User Function AOMS072Q() 
 Local _lRet := .T. As Logical
 Local _aOrd := SaveOrd({"ZFC","ZF5"}) As Array
 Local _cTipoOcorr  := 0 As Char
 Local _cTipoCusto  := 0 As Char
 Local _nI          := 0 As Numeric
 Local _nCustoIt    := 0 As Numeric
 Local _nCustoCli   := 0 As Numeric
 Local _nCustoRepr  := 0 As Numeric
 Local _nCustoTransp:= 0 As Numeric
 Local _nCustoTerc  := 0 As Numeric
 Local _cGerDevol   := 0 As Numeric
 Local _cServOcorr  := 0 As Numeric
 Local _cNfDev      := 0 As Numeric
 Local  _cSerDev    := 0 As Numeric
 Local _nTIPOO      := 0 As Numeric
 Local _nTIPOC      := 0 As Numeric
 Local _nCUSTOI     := 0 As Numeric
 Local _nCUSTOC     := 0 As Numeric
 Local _nCUSTOR     := 0 As Numeric
 Local _nCUSTOT     := 0 As Numeric
 Local _nCUSTER     := 0 As Numeric
 Local _nDEVOL      := 0 As Numeric
 Local _nSERVIC     := 0 As Numeric
 Local _nDOCDEV     := 0 As Numeric
 Local _nSERDEV     := 0 As Numeric
 Local _nZF5_CAUCUS := 0 As Numeric
 Local _nZF5_VLRTOT := 0 As Numeric
 Local _nZF5_VALEMB := 0 As Numeric

Begin Sequence 
   //================================================================================
   // Pega a posição dos campos dentro do aCols
   //================================================================================
   For _nI := 1 To Len(aHeader)     
       If AllTrim(aHeader[_nI,2]) == "ZF5_TIPOO"
          _nTIPOO := _nI // Tipo Ocorrência         
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_TIPOC"
          _nTIPOC := _nI // Tipo de custo.
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOI"
          _nCUSTOI := _nI // Custo Italac        
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOC"
          _nCUSTOC := _nI // Custo cliente       
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOR"
          _nCUSTOR := _nI // Custo Representante 
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTOT"
          _nCUSTOT := _nI // Custo Transportador 
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTO"
          _nCUSTO := _nI // Custo da ocorrência
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CUSTER"
          _nCUSTER := _nI // Custo Terceiro      
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_DEVOL"                              
          _nDEVOL  := _nI // Gera Devolução S/N  
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_SERVIC"
          _nSERVIC := _nI // Serviço Ocorrência - 1=Descarga;2=Deslocamento;3=Diaria;4=Reentrega;5=outros
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_DOCDEV"
          _nDOCDEV := _nI // Nota Fiscal de devolução 
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_SERDEV"
          _nSERDEV := _nI // Nota Fiscal de devolução
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_MOTCUS"
          _nCUSMOT := _nI // Motivo do custo 
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_DOCDEV"
          _nDOCDEV := _nI // Nota Fiscal de devolução           
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_STATUS"
          _nCUSSTA := _nI // Status da ocorrência     
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CAUCUS"
          _nZF5_CAUCUS := _nI //   Causador do Custo.
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_VLRTOT"
          _nZF5_VLRTOT := _nI // Valor total da ocorrência 
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_VALEMB"
          _nZF5_VALEMB := _nI // Valor Embutido no Frete
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_OLRCOD"
          _nZF5_OLRCOD := _nI // Código do operador logístico do redirecionamento
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_OLRLOJ"
          _nZF5_OLRLOJ := _nI // Loja do operador logístico do redirecionamento
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_CODIGO"
          _nZF5_CODIGO := _nI // Codigo da ocorrência
       ElseIf AllTrim(aHeader[_nI,2]) == "ZF5_DTOCOR"
          _nZF5_DTOCOR := _nI // Codigo da ocorrência
       EndIf    
   Next

   //================================================================================
   // Realiza validações no aCols
   //================================================================================                            
   For _nI := 1 To Len(aCols)
      
       _cTipoOcorr   := aCols[_nI,_nTIPOO]   // Tipo Ocorrência
       _cTipoCusto   := aCols[_nI,_nTIPOC]   // Tipo de custo.
       _nCustoIt     := aCols[_nI,_nCUSTOI]  // Custo Italac
       _nCustoCli    := aCols[_nI,_nCUSTOC]  // Custo cliente 
       _nCustoRepr   := aCols[_nI,_nCUSTOR]  // Custo Representante
       _nCustoTransp := aCols[_nI,_nCUSTOT]  // Custo Transportador
       _nCustoTerc   := aCols[_nI,_nCUSTER]  // Custo Terceiro                                    
       _cGerDevol    := aCols[_nI,_nDEVOL]   // Gera Devolução S/N
       _cServOcorr   := aCols[_nI,_nSERVIC]  // Serviço Ocorrência - 1=Descarga;2=Deslocamento;3=Diaria;4=Reentrega;5=outros
       _cNfDev       := aCols[_nI,_nDOCDEV]  // Nota Fiscal de devolução 
       _cSerDev      := aCols[_nI,_nSERDEV]  // Serie da Nota Fiscal de Devolução
       _nvaltransp   := aCols[_nI,_nCUSTOT]
       _nvaltot      := aCols[_nI,_nCUSTO]
       _nvalita      := aCols[_nI,_nCUSTOI]
       _nvalrep      := aCols[_nI,_nCUSTOR]
       _nvalcli      := aCols[_nI,_nCUSTOC]
       _nvalter      := aCols[_nI,_nCUSTER]
       _nValoco      := aCols[_nI,_nZF5_VLRTOT]
       _nValemb      := aCols[_nI,_nZF5_VALEMB]
       _cZF5_OLRCOD  := aCols[_nI,_nZF5_OLRCOD] // Código do operador logístico do redirecionamento
       _cZF5_OLRLOJ  := aCols[_nI,_nZF5_OLRLOJ] // Loja do operador logístico do redirecionamento
       _cCodigo      := AllTrim(aCols[_nI,_nZF5_CODIGO]) // Código da ocorrência por nota
       _dDataOcorr   := aCols[_nI,_nZF5_DTOCOR]
       
       //Validando campos obrigatórios
       If (Empty(_cTipoOcorr) .Or. ((Empty(_cTipoCusto) .Or. Empty(aCols[_nI,_nCUSMOT])) .And. _nvaltot > 0) .Or. Empty(aCols[_nI,_nCUSSTA]) ) 
          Help( ,, "Atenção 001",, 'Ocorrência ' + _cCodigo + " - Existem campos obrigatórios não preenchidos (Tipo ocorrência, Tipo custo, motivo de custo e/ou Status)",1,0)
          _lRet := .F.
          Exit 
      EndIf   

       //Validando total de valores de cada linha  		  		
       If _nvaltot <> (_nvaltransp+_nvalita+_nvalrep+_nvalcli+_nvalter+_nValemb)                 
          Help( ,, "Atenção 002",, 'Ocorrência ' + _cCodigo + " - Custo total da ocorrência deve ser igual à somatória dos custos Italac, cliente, representante, transportador e terceiros ",1,0)
         _lRet := .F.
         Exit    
       EndIf

       //Validando total de valores de cada linha  		  		
       If _nvaloco <> (_nvaltransp+_nvalita+_nvalrep+_nvalcli+_nvalter)
          Help( ,, 'Atenção 003',, 'Ocorrência ' + _cCodigo + ' - Custo da ocorrência deve ser igual à somatória dos custos Italac, ' + ;
                   ' cliente, representante, transportador, terceiros ' , 1, 0, .F. )
           _lRet := .F.
          Exit
       EndIf

       //Validando total de valores de cada linha  		  		
       If _nvaltot > 0 .And. Empty(aCols[_nI,_nZF5_CAUCUS] )
          Help( ,, 'Atenção 004',,'Ocorrência ' + _cCodigo + ' - Se tem Valor de custo o campo "Causador do Custo" deve ser informado.', 1, 0, .F. )
          _lRet := .F.
          Exit
       EndIf

       ZFC->(DBSetOrder(1))
       If ZFC->(DBSeek(xFilial("ZFC")+_cTipoOcorr))  
          If ZFC->ZFC_OLREDI  == "S"
             If Empty(_cZF5_OLRCOD) .Or. Empty(_cZF5_OLRLOJ)
                _lRet := .F.
                U_ITMsg('Ocorrência ' + _cCodigo + ' - Tipo de ocorrecia é de redirecionamento. (ZFC_OLREDI="S").','Atenção',;
                        "Informe o Codigo do operador logistico do redirecionamento.",,,,.T.)
                Break
             EndIf
          Else
             If !Empty(_cZF5_OLRCOD) .Or. !Empty(_cZF5_OLRLOJ)
                _lRet := .F.
                U_ITMsg('Ocorrência ' + _cCodigo + ' - Tipo de ocorrecia não é de redirecionamento. (ZFC_OLREDI<>"S").','Atenção',;
                        'O Codigo do operador logistico do redirecionamento não pode ser informado.',,,,.T.)
                Break
             EndIf
          EndIf
       EndIf

       If _dDataOcorr > Date() .And. ZFC->ZFC_DTTRAN <> "F"
          Help( ,, 'Atenção',, 'Ocorrência ' + _cCodigo + ', Data da ocorrencia '+DToC(_dDataOcorr)+' não pode ser maior que Hoje.' , 1, 0 )
          _lRet := .F.
          Break
       EndIf
 
       SF2->(DBSeek(xFilial("SF2")+M->ZF5_DOCOC+M->ZF5_SEROC))
       If _dDataOcorr < SF2->F2_EMISSAO
          Help( ,, 'Atenção',, 'Ocorrência ' + _cCodigo + ', Data da ocorrencia '+DToC(_dDataOcorr)+' não pode ser menor que emissao da NF: '+DToC(SF2->F2_EMISSAO) , 1, 0 )
          _lRet := .F.
          Break
       EndIf

       If !Empty(ZFC->ZFC_CUSTO) .And. ZFC->ZFC_CUSTO <>  _cTipoCusto
          _lRet := .F.
          Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O tipo de custo informado, difere do tipo de custo do tipo de ocorrência.", 1, 0 )
          Exit
       ElseIf _cTipoCusto == "I" // Italac
          If Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O campo custo italac deve ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. ! Empty(_nCustoCli) .Or. ! Empty(_nCustoTerc)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - Por ter selecionado o tipo de custo Italac, você deve preencher apenas o campo de valor de custo Italac.", 1, 0 )
             Exit
          EndIf
       ElseIf _cTipoCusto == "T" // Transportador
          If Empty(_nCustoTransp)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O campo custo transportador deve ser preenchido.", 1, 0 )        
             Exit
          EndIf
       ElseIf _cTipoCusto == "R" // Representante
          If Empty(_nCustoRepr)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O campo custo representante deve ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoCli) .Or. ! Empty(_nCustoTerc) .Or. !Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - Por ter selecionado o tipo de custo Representante, você deve preencher apenas o campo de valor de custo Representante.", 1, 0 )
             Exit
          EndIf           
       ElseIf _cTipoCusto == "C" // Cliente
          If Empty(_nCustoCli)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O campo custo cliente precisa ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. ! Empty(_nCustoTerc) .Or. !Empty(_nCustoIt)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - Por ter selecionado o tipo de custo Cliente, você deve preencher apenas o campo de valor de custo Cliente.", 1, 0 )
             Exit
          EndIf

       ElseIf _cTipoCusto == "3" // Terceiros 
          If Empty(_nCustoTerc)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O campo custo de Terceiros precisa ser preenchido.", 1, 0 )
             Exit
          ElseIf ! Empty(_nCustoRepr) .Or. !Empty(_nCustoIt) .Or. ! Empty(_nCustoCli)
             _lRet := .F.
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - Por ter selecionado o tipo de custo Terceiro, você deve preencher apenas o campo de valor de custo Terceiro.", 1, 0 )
             Exit
          EndIf          
       EndIf
       
       If _cGerDevol == "S"
          If Empty(_cNfDev) .Or. Empty(_cSerDev)
             _lRet := .F. 
             Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O numero e série da nota fiscal de devolução devem ser preenchidos, pois o tipo de custo informado gera devolução.", 1, 0 )
             Exit
          EndIf
       EndIf
       
       If !Empty(ZFC->ZFC_SERVI) .And. _cServOcorr <> ZFC->ZFC_SERVI 
          _lRet := .F. 
          Help( ,, "Atenção",, 'Ocorrência ' + _cCodigo + " - O tipo de serviço informado difere de tipo de serviço do tipo de ocorrência.", 1, 0 )
          Exit
       EndIf       
   Next

End Sequence

RestOrd(_aOrd)

Return _lRet

/*
===============================================================================================================================
Programa--------: AOMS072S
Autor-----------: Julio de Paula Paz
Data da Criacao-: 23/04/2018
===============================================================================================================================
Descrição-------: Retornar a próxima sequência numérica disponível.
===============================================================================================================================
Parametros------: _nRecnoSF2 = numero do recno da Tabela SF2.
===============================================================================================================================
Retorno   ------: _nRet = próxima sequência do item da ocorrencia de frete.
===============================================================================================================================
*/
User Function AOMS072S(_cCodFilial,_cNrNf,_cSerieNf) 
Local _nRet := 0
Local _nRegAtu := ZF5->(Recno())

Begin Sequence
   ZF5->(DBSetOrder(1)) // ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC
   ZF5->(DBSeek(_cCodFilial+U_ITKEY(_cNrNf,"ZF5_DOCOC")+U_ITKEY(_cSerieNf,"ZF5_SEROC")))
   While ! ZF5->(Eof()) .And. ZF5->(ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC) == _cCodFilial+_cNrNf+_cSerieNf
      If Val(AllTrim(ZF5->ZF5_CODIGO)) > _nRet
         _nRet := Val(AllTrim(ZF5->ZF5_CODIGO)) 
      EndIf
      
      ZF5->(DBSkip()) 
   EndDo

   _nRet += 1
   
End Sequence

ZF5->(DBGoTo(_nRegAtu))

Return _nRet
