/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer |21/03/2025| Chamado 50197.Novo tratamento para cortes e desmembramentos de pedidos - IGNORAR: M->C5_I_BLSLD = "S"
Lucas Borges  |23/07/2025| Chamado 51340. Ajustar função para validação de ambiente de teste
Lucas Borges  |14/09/2025| Chamado 51799. Implementada função para validar ambiente de teste totvs.framework.environment.Type.get()
===============================================================================================================================
*/

#Include "TOTVS.ch"
#Include "msmgadd.ch"
#Include "dbtree.ch"

#DEFINE LEGENDAS_ABCP "BR_AMARELO/BR_BRANCO/BR_CINZA/BR_PRETO"

/*
===============================================================================================================================
Programa--------: MOMS066 // U_MOMS066
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Geracao lista de Pedidos Pendentes / Monitor de Pedidos. CHAMADO 40644 
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================
*/
User Function MOMS066

Local _aParAux  := {} As Array, nI As Numeric
Local _aParRet  := {} As Array
Local _lLoop    := .F. As Logical

Private _lAmbTeste  := !totvs.framework.environment.Type.get() == '1' As Logical //1-Produção, 2-Homologação,3-Desenvolvimento
Private _aOpcCart   := { '1-Sim', '2-Não'} As Array
Private _aOpcLibEs  := { '1-Sim', '2-Não'} As Array
Private _cFilPrc    := cFilAnt As Character
Private lRegioes    := .F. As Logical //ATUALIZADO DENTRO DA MOMS66Obj ()
Private cPastaR     := "" As Character //ATUALIZADO DENTRO DA MOMS66Obj ()
Private cOrigemDebug:= "INICIO" As Character //PARA VER NO DEBUG E NO ERROR.LOG
Private _cFilTer    := AllTrim(SuperGetMV('IT_EST3FIL',.T.,'')) As Character // Verifica parâmetro de configurações das Filiais que usam estoque em poder de terceiros
Private _cLocTer    := AllTrim(SuperGetMV('IT_EST3LOC',.T.,'')) As Character // Verifica parâmetro de configurações dos Armazéns que usam estoque em poder de terceiros
Private lClicouMarca:= .F. As Logical ///Desativa a atualização na troca de pasta
Private _aOpcTran   := {"Com Transferencias", "Sem Transferencias", "Só Transferências"} As Array
Private _aOpcTpCar  := {"Carga Refrigerada", "Carga Seca", "Todas"} As Array
Private _nPesoMax   := If(_lAmbTeste, 0, 9999999) As Numeric //Peso máximo Operador logístico - ZEL_PMAXOL 

_cSelectSB1:="SELECT B1_COD , B1_TIPO, B1_DESC FROM "+RETSQLNAME("SB1")+" SB1 WHERE D_E_L_E_T_ = ' ' AND B1_MSBLQL <> '1' AND B1_TIPO = 'PA'  ORDER BY B1_COD "

_cSelectZLE:="SELECT ZEL_CODIGO, ZEL_DESCRI, ZEL_LOCAL FROM "+RETSQLNAME("ZEL")+" ZEL WHERE D_E_L_E_T_ = ' ' AND ZEL_FILFIS = '"+_cFilPrc+"'  ORDER BY ZEL_CODIGO "

_aGerProd:={}

_aItalac_F3:={}//       1           2         3                      4                      5               6                    7         8          9         10         11        12
//AD(_aItalac_F3,{"1CPO_CAMPO1",_cTabela ,_nCpoChave              , _nCpoDesc              ,_bCondTab    , _cTitAux            , _nTamChv, _aDados , _nMaxSel    , _lFilAtual,_cMVRET,_bValida})
aAdd(_aItalac_F3,{"MV_PAR03" ,_cSelectZLE,{|Tab|(Tab)->ZEL_CODIGO},{|Tab|(Tab)->ZEL_LOCAL+" "+(Tab)->ZEL_DESCRI}, ,"Local de Embarque"  ,         ,         ,1            ,.F.        ,       , } )
aAdd(_aItalac_F3,{"MV_PAR04" ,_cSelectSB1,{|Tab|(Tab)->B1_COD},{|Tab|(Tab)->B1_TIPO+" "+(Tab)->B1_DESC}, ,"Produtos"           ,         ,         ,20           ,.F.        ,       , } )
mTam:=Len(SC6->C6_PRODUTO+SC6->C6_LOCAL)//11+Len(SC6->C6_LOCAL)
aAdd(_aItalac_F3,{"M->ZPQ_PRODUT",       ,                    ,                                          , ,"Produtos Lidos"     ,mTam     ,_aGerProd,1})

While .T.

    MV_PAR01:=_dDataDia:=Date()
    MV_PAR02:=SuperGetMV("IT_MOMS66H",.T.,"14:00")
    MV_PAR03:=Space(004)
    MV_PAR04:=Space(200)
    MV_PAR05:=Space(050)
    MV_PAR06:=Space(200) 
    MV_PAR07:=1
    MV_PAR08:=1
    MV_PAR09:=2
    MV_PAR10:=3
    MV_PAR11:=2

    _cTitulo:="Lista de Pedidos Pendentes / Monitor de Pedidos"
        
    If !_lLoop//Para não duplicar quando der Loop

        If !_lAmbTeste
           aAdd( _aParAux , { 9 , "DATA DE EMISSAO DO PEDIDO ATE "+DToC(_dDataDia), 150 , 9, .T. } )
        Else
           aAdd( _aParAux , { 1 , "Data Emissao ate", MV_PAR01, "@D"  , "" ,"", ".T." , 070 , .T. } )
        EndIf
        aAdd( _aParAux , { 9 , "HORA DO PEDIDO ATE "+ MV_PAR02  , 150 , 9, .T. } )
        
        aAdd( _aParAux , { 1 , "Local de Embarque"              , MV_PAR03, "@!"  , ""  ,"F3ITLC", "" , 100 , .T. } ) 
        aAdd( _aParAux , { 1 , "Produtos"                       , MV_PAR04, "@!"  , ""  ,"F3ITLC", "" , 100 , .F. } ) 
        aAdd( _aParAux , { 1 , "Tipo de Agendamento"            , MV_PAR05, "@!"  , ""  ,"LSTAGE", "" , 100 , .F. } ) 
        aAdd( _aParAux , { 1 , "Gerente"                        , MV_PAR06, "@!"  , ""  ,"LSTGER", "" , 100 , .F. } )
        
        aAdd( _aParAux , { 3 , "Carteira Toda"                  , MV_PAR07,_aOpcCart , 60 , '' , .T. } )
        aAdd( _aParAux , { 3 , "Tranferecias"                   , MV_PAR08,_aOpcTran , 60 , '' , .T. } )
        aAdd( _aParAux , { 3 , "Considerar Liberação de Estoque", MV_PAR09,_aOpcLibEs, 60 , '' , .T. } )
        aAdd( _aParAux , { 3 , "Tipo de Carga"                  , MV_PAR10,_aOpcTpCar, 60 , '' , .T. } )
        aAdd( _aParAux , { 3 , "Dobrar a Capacidade"            , MV_PAR11,_aOpcLibEs, 60 , '' , .T. } )
              
        For nI := 1 To Len( _aParAux )
            aAdd( _aParRet , _aParAux[nI][03] )
        Next 
        _lLoop:=.T.
     
     EndIf
           
     // 1-aParametros,2-cTitle                                   ,3-aRet    ,4-bOk      ,5-aButtons,6-lCentered,7-nPosX,8-nPosY,9-oDlgWizard,10-cLoad,11-lCanSave,12-lUserSave
     If !ParamBox( _aParAux    , "CONFIRME A LEITURA DOS PEDIDOS PENDENTES", _aParRet , {|| .T. } ,          ,           ,       ,       ,            ,        , .T.       , .T.        )
         Return .T.
     EndIf

     _dDataDia:=MV_PAR01

     If ValType(MV_PAR07) = "C"
        MV_PAR07:=Val(MV_PAR07)
     EndIf
     If ValType(MV_PAR08) = "C"
        MV_PAR08:=Val(MV_PAR08)
     EndIf
       
     _cTitulo+=" - "+DToC(_dDataDia)+" - "+Time()
     ZEL->(DBSetOrder(1))//  // ZEL_FILIAL+ZEL_CODIGO         // COMPARTILHADA
     If !ZEL->(DBSeek(xFilial()+AllTrim(MV_PAR03))) .Or. (ZEL->ZEL_FILFIS <> _cFilPrc)
        U_ITMsg('Local de embarque "'+AllTrim(MV_PAR03)+'" NÃO cadastrado para essa filial: '+_cFilPrc,'Atenção!',"Selecione um Local de embarque via F3 por favor." ,1)    
        Loop
     EndIf
     ZEL->(DBSetOrder(1))  // ZEL_FILIAL+ZEL_CODIGO         // COMPARTILHADA
     If ZEL->(FIELDPOS("ZEL_MULPAL")) > 0  .And. ZEL->(FIELDPOS("ZEL_MULPES")) > 0 
        
        If ZEL->(DBSeek(xFilial()+AllTrim(MV_PAR03))) .AND.;
                                 !Empty(ZEL->ZEL_CAPKG ) .AND.;
                                 !Empty(ZEL->ZEL_CAPALE) .AND.;
                                 !Empty(ZEL->ZEL_MULPAL) .AND.;
                                 !Empty(ZEL->ZEL_MULPES)
          _nCapacPes:= ZEL->ZEL_CAPKG  //Capacidade peso
          _nCapacPal:= ZEL->ZEL_CAPALE //Capacidade de Palete
          _cMultPall:= AllTrim(ZEL->ZEL_MULPAL) //Multiplo de Paletes
          _cMultPeso:= AllTrim(ZEL->ZEL_MULPES) //Multiplo de Pesos  
          If ZEL->(FIELDPOS("ZEL_PMAXOL")) > 0 .And. !Empty(ZEL->ZEL_PMAXOL)
             _nPesoMax := ZEL->ZEL_PMAXOL //Peso máximo Operador logístico
          EndIf	    
        Else
          
          _cCampo :=""
          If Empty(ZEL->ZEL_CAPKG)
             _cCampo += '[capacidade de peso] '
          EndIf
          If Empty(ZEL->ZEL_CAPALE) 
             _cCampo += '[capacidade de paletes] ' 
          EndIf
          If Empty(ZEL->ZEL_MULPAL) 
             _cCampo += '["multiplo de Paletes] ' 
          EndIf
          If Empty(ZEL->ZEL_MULPES)   
             _cCampo += '["multiplo de peso]' 
          EndIf
          If ZEL->(FIELDPOS("ZEL_PMAXOL")) > 0 .And. Empty(ZEL->ZEL_PMAXOL)
             _cCampo += '[Peso máximo Operador logístico]' 
          EndIf

          U_ITMsg('Cadastro de Local de embarque "'+MV_PAR03+'" esta incompleto.','Atenção!',"Cadastre o(s) campo(s): "+_cCampo ,1)    
          
          If _lAmbTeste
             ZEL->(DBSeek(xFilial()+AllTrim(MV_PAR03))) 
             Z24->(DBSeek(xFilial()+_cFilPrc+"  "))// Procura para todas as filiais
             _nCapacPes:=If(Empty(ZEL->ZEL_CAPKG ),Z24->Z24_PESO       ,ZEL->ZEL_CAPKG)
             _nCapacPal:=If(Empty(ZEL->ZEL_CAPALE),(Z24->Z24_PESO/1000),ZEL->ZEL_CAPALE)
             _cMultPall:=If(Empty(ZEL->ZEL_MULPAL),"01 / 02 / 03 / 10",AllTrim(ZEL->ZEL_MULPAL))
             _cMultPeso:=If(Empty(ZEL->ZEL_MULPES),"01 / 02 / 04 / 10",AllTrim(ZEL->ZEL_MULPES))
             U_ITMsg("Como esta no Ambiente "+GetEnvServer()+" que não é produção, será usado os seguintes valores :"+CRLF;
                      +"Capacidade de peso: "+cValToChar(_nCapacPes)+CRLF;
                      +"Capacidade de paletes: "+cValToChar(_nCapacPal)+CRLF;
                      +"Multiplo de Paletes: "+_cMultPall+CRLF;
                      +"Multiplo de peso: "+_cMultPeso+CRLF;
                      +"Peso máximo Operador logístico: "+cValToChar(_nPesoMax);
                      ,'Atenção!', ,2)    
          Else
             Loop
          EndIf
        
        EndIf
    Else
       ZEL->(DBSeek(xFilial()+AllTrim(MV_PAR03))) 
       Z24->(DBSeek(xFilial()+_cFilPrc+"  "))// Procura para todas as filiais
       _nCapacPes:=If(Empty(ZEL->ZEL_CAPKG ),Z24->Z24_PESO       ,ZEL->ZEL_CAPKG)
       _nCapacPal:=If(Empty(ZEL->ZEL_CAPALE),(Z24->Z24_PESO/1000),ZEL->ZEL_CAPALE)
       _cMultPall:="12 / 28 / 44 / 48"
       _cMultPeso:="14 / 30 / 46 / 50"
    EndIf

    If !Empty(MV_PAR03)
        _cTitulo+=" - Local: "+AllTrim(MV_PAR03)
    EndIf
    If !Empty(MV_PAR04)
        _cTitulo+=" - Prods: "+AllTrim(MV_PAR04)
    EndIf
    If !Empty(MV_PAR05)
        _cTitulo+=" - Tipos: "+AllTrim(MV_PAR05)
    EndIf
    If !Empty(MV_PAR06)
        _cTitulo+=" - Gerentes: "+AllTrim(MV_PAR06)
    EndIf	
    
   If _nCapacPes <= 0
       U_ITMsg("Filial "+_cFilPrc+" sem limite de carregamento cadastrada",'Atenção!',"Cadastre um limite de carragamento para a filial : "+_cFilPrc,3) 
       Loop
    EndIf

    If MV_PAR11 = 1
       _nCapacPes:=(_nCapacPes*2)
       _nCapacPal:=(_nCapacPal*2)
    EndIf

    While .T.
       
          cSair := "SAIR"
          FWMsgRun(,{|oProc|  cSair := MOMS66CP(oProc)  }, "Analisando os Pedidos...","Filtrando pedidos pendentes..." )
        
          Exit
        
    EndDo
    
    If cSair = "SAIR"
       Exit
    EndIf

EndDo
    
Return

/*
===============================================================================================================================
Programa--------: MOMS66CP
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Pego os pedidos necessários para realizar a manutenção na tabela ZY3
Parametros------: oProc - objeto para o carregamento do FWMsgRun quando a tela estiver ativa.
Retorno---------: cSair: "Loop" ou "SAIR"
===============================================================================================================================*/
Static Function MOMS66CP(oProc)

Local _cQuery        := "" As Character, P As Numeric, M As Numeric
Local _cAlias2       := GetNextAlias() As Character
Local _cTpOper       := SuperGetMV("IT_OMS48TO",.T.,'02;07;15;18;19;21;22;23;31;40;41;50;51;99') As Character
Local _cAliasC9      := GetNextAlias() As Character

Private _cOper50     := AllTrim(SuperGetMV("IT_CHEPCLS",.T.,'') ) As Character //OPERAÇÃO EXCLUSIVA PARA CLIENTE CHEP
Private _cOper51     := AllTrim(SuperGetMV("IT_CHEPCLN",.T.,'') ) As Character //OPERAÇÃO EXCLUSIVA PARA CLIENTE NÃO CHEP
Private _dHoje       := _dDataDia As Date
Private _lEfetivar   := .T. As Logical //DESBLOQUEIA O BOTÃO GERAR
Private _aSB2        := {} As Array
Private _aSB2Inic    := {} As Array
Private _aPedidos    := {} As Array
Private _lGravaLOG   :=.F. As Logical
Private _lGrava      :=.F. As Logical
Private _lSimular    :=.F. As Logical
Private _nTotPesoLib := 0 As Numeric
Private _nTotPalsLib := 0 As Numeric
Private _nSEstPesoLib:= 0 As Numeric //TOTAL LIBERADO SEM OLHA ESTOQUE 
Private _nSEstPalsLib:= 0 As Numeric //TOTAL LIBERADO SEM OLHA ESTOQUE 
Private _nPesSaldoIni:= 0 As Numeric
Private _aItensSemEstoque:= {} As Array

If oProc <> NIL
   oProc:cCaption := ("Filtrando pedidos pendentes..." )
   ProcessMessages()
EndIf
SC5->(DBSetOrder(1))
SC6->(DBSetOrder(1))
SB1->(DBSetOrder(1))
Z24->(DBSetOrder(1))

If !_lAmbTeste
   _dHoje:=_dDataDia:=Date() // POR GARANTIA
EndIf

_cQuery := "SELECT C5.R_E_C_N_O_ C5REC "
_cQuery += "FROM " + RetSqlName("SC5") + " C5 "
_cQuery += "WHERE C5_TIPO = 'N' " 
_cQuery += "  AND C5_NOTA = ' ' "
_cQuery += "  AND (C5_EMISSAO < '" + DToS(_dHoje)+"' "
_cQuery += "       OR (C5_EMISSAO = '" + DToS(_dHoje)+"' AND C5_I_HREMI <= '"+MV_PAR02+"')) "

_cQuery += "  AND (C5_I_AGEND IN ('M','A','I','O') OR (C5_I_OPER = '20' AND C5_I_TRCNF <> 'S')) "

// Filtra Agendamento
If !Empty( MV_PAR05 )      
    If Len(AllTrim(MV_PAR05)) = 1
        _cQuery += "AND C5_I_AGEND = '"+ AllTrim(MV_PAR05) + "' "
    Else
        _cQuery += "AND C5_I_AGEND IN "+ FormatIn(AllTrim(MV_PAR05), ";" )
    EndIf
EndIf
// Filtra Gerente
 If !Empty( MV_PAR06 )             
     If Len(AllTrim(MV_PAR06)) <= 6
         _cQuery += " AND C5_VEND3 = '"+ AllTrim(MV_PAR06) + "' "
     Else
         _cQuery += " AND C5_VEND3 IN "+ FormatIn( AllTrim(MV_PAR06) , ";" )
     EndIf
 EndIf
_cQuery += "  AND C5_FILIAL = '"+_cFilPrc+"' "
_cQuery += "  AND NOT C5_I_OPER IN " + FormatIn(_cTpOper, ";") + " " 
// Filtra Local DE EMBARQUE
If !Empty( MV_PAR03 )      
   _cQuery += "              AND C5_I_LOCEM = '"+ AllTrim(MV_PAR03) + "' "
EndIf

//FILTRA: 1-Com Transferencias  / 2-Sem Transferencias / 3-Só Transferências
If MV_PAR08 = 2 
   _cQuery += "              AND C5_I_OPER <> '20' "
ElseIf MV_PAR08 = 3
   _cQuery += "              AND C5_I_OPER  = '20' "
EndIf

//Novo tratamento para cortes e desmembramentos de pedidos - IGNORAR: M->C5_I_BLSLD = "S"
If SC5->(FIELDPOS("C5_I_BLSLD")) > 0
   _cQuery += " AND C5_I_BLSLD = 'N' "
EndIf

_cQuery += "  AND C5.D_E_L_E_T_  = ' ' " 
_cQuery += "  AND EXISTS (SELECT 'Y' FROM " +RetSqlName("SC6")+" C6, " + RetSqlName("SB1") + " B1 "
_cQuery += "               WHERE C6.D_E_L_E_T_ = ' ' AND C6.C6_FILIAL = C5.C5_FILIAL AND C6.C6_NUM = C5.C5_NUM "
// Filtra PRODUTO
If !Empty( MV_PAR04 )      
    If Len(AllTrim(MV_PAR04)) <= 11
        _cQuery += "             AND C6_PRODUTO = '"+ AllTrim(MV_PAR04) + "' "
    Else
        _cQuery += "             AND C6_PRODUTO IN "+ FormatIn(AllTrim(MV_PAR04), ";" )
    EndIf
EndIf
_cQuery += "                     AND B1.D_E_L_E_T_ = ' ' AND B1.B1_FILIAL = ' ' AND B1.B1_COD = C6.C6_PRODUTO "

_cQuery += "                     AND B1_TIPO = 'PA' AND C6_LOCAL NOT IN ( '40','42') ) "	

_cQuery += "  AND NOT EXISTS (SELECT 'Y' FROM " +RetSqlName("SC9")+" C9 WHERE C9.D_E_L_E_T_ = ' ' AND C9.C9_FILIAL = C5.C5_FILIAL AND C9.C9_PEDIDO = C5.C5_NUM ) "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias2 , .T. , .F. )

_nTot:=nConta:=0
COUNT TO _nTot
_cTotGeral:=AllTrim(Str(_nTot))

(_cAlias2)->(DBGoTop())
If (_cAlias2)->(Eof())
    U_ITMsg("Não existe pedidos para processamento.",'Atenção!',,3) 
    Return "Loop"
EndIf
    
If !U_ITMsg("Serão processados "+_cTotGeral+' Pedidos da Filial Atual: '+_cFilPrc+', Confirma ?','Atenção!',,3,2,3,,"CONFIRMA","VOLTAR")
   Return "Loop"
EndIf

If oProc <> NIL
   oProc:cCaption := ("1-Calculando Saldo Inicial do Carregamento..." )
   ProcessMessages()
EndIf

_cQuery := " SELECT DISTINCT C9.C9_FILIAL,C9.C9_PEDIDO "
_cQuery += " FROM " +RetSqlName("SC9")+" C9 "
_cQuery += " WHERE C9.D_E_L_E_T_ = ' ' "
_cQuery += "   AND C9.C9_FILIAL  = '"+_cFilPrc+"' "
If !_lAmbTeste
   _cQuery += "AND C9.C9_DATALIB = '" + DToS(_dHoje)+"' "
Else
   _cQuery += "AND C9.C9_DATALIB >= '" + DToS(_dHoje)+"' "
EndIf
_cQuery += "  AND EXISTS "
_cQuery += "     (SELECT 'Y' FROM " +RetSqlName("SC5")+" C5 WHERE " 
_cQuery += "                                             C5.D_E_L_E_T_ = ' '          AND "
_cQuery += "                                             C5.C5_FILIAL  = C9.C9_FILIAL AND "
_cQuery += "                                             C5.C5_NUM     = C9.C9_PEDIDO AND "
If !Empty( MV_PAR03 )      // Filtra Local DE EMBARQUE
   _cQuery += "                                          C5_I_LOCEM    = '"+ AllTrim(MV_PAR03) + "' AND "
EndIf
If !_lAmbTeste
   _cQuery += "                                          C5.C5_I_LILO  = '" + DToS(_dHoje)+"' ) "
Else
   _cQuery += "                                          C5.C5_I_LILO  >= '" + DToS(_dHoje)+"' ) "//No ambiente de testes vc tem que selcionar uma data antiga mas gera com a data do dia do teste Date()
EndIf

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAliasC9 , .T. , .F. )

SC5->(DBSetOrder(1))
_nPesSaldoIni:=0
_nPalSaldoIni:=0
While (_cAliasC9)->(!Eof())
   
   If SC5->(DBSeek( (_cAliasC9)->C9_FILIAL+(_cAliasC9)->C9_PEDIDO)) 
       
      M->C5_I_TIPCA:=SC5->C5_I_TIPCA
      If !M->C5_I_TIPCA $ "1/2"
         M->C5_I_TIPCA :="2"//-Batida"
         SA1->(DBSetOrder(1))                         
         If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
            If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
                M->C5_I_TIPCA :="1"//-Paletizada"//PALETE CHEP
            Else
                M->C5_I_TIPCA :="2"//-Batida"    //ESTIVADA
            EndIf   
         EndIf
         If SC5->C5_I_OPER == _cOper50 .Or. SC5->C5_I_OPER == _cOper51 //PEDIDO DE PALLET DEVE SER ENVIADO COMO ESTIVADO
            M->C5_I_TIPCA :="2"//-Batida"
         EndIf
      EndIf

      If  M->C5_I_TIPCA = "1" .And. SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
          _nTotPall:=0
          While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
               _nTotPall+=MOMS66CT(SC6->C6_PRODUTO,SC6->C6_QTDVEN,.T.)
               SC6->(DBSkip())
          EndDo
          _nPalSaldoIni+=_nTotPall      //Paletizada
      Else                     
          _nPesSaldoIni+=SC5->C5_I_PESBR//Batida
      EndIf
   EndIf   
   (_cAliasC9)->(DBSkip())
EndDo

aPedVin:={}
aFolderRGBR:={}//Preenchido na funcao ITRegiaoBR ()
aFolderMeso:={}
While (_cAlias2)->(!Eof())
        
    SC5->(DBGoTo((_cAlias2)->C5REC))
    If oProc <> NIL
       nConta++
       oProc:cCaption := ("2-Lendo Ped.: "+SC5->C5_NUM+" - "+StrZero(nConta,5) +" de "+ _cTotGeral )
       ProcessMessages()
    EndIf

    _aSC6_do_PV:= {}
    _cClassEnt:=Posicione("SA1",1,xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI,"A1_I_CLABC")
    If _cClassEnt = '1'
       _cClassEnt:="1-TOP 1 NACIONAL"
    ElseIf _cClassEnt = '2'
       _cClassEnt:="2-TOP 5 Reg. SP "
    ElseIf _cClassEnt = '3'
       _cClassEnt:="3-TOP 5 Reg. RS "
    EndIf

    _dDataCalculada:=SC5->C5_I_DTENT //Usado na funcao MOMS66Ord ()
    _cObs  :=""                      //Preenchido na funcao MOMS66Ord ()
    _nDias :=0                       //Preenchido na funcao MOMS66Ord ()
    _lAchouZG5:=.F.                  //Preenchido na funcao MOMS66Ord ()
    _cRegra:=""                      //Preenchido na funcao MOMS66Ord ()
    
    _cChave:=MOMS66Ord(_cClassEnt)   //BUSCA A CHAVE DE PRIORIDADE 

    If _cChave == "Loop"
       (_cAlias2)->(DBSkip())
       Loop
    EndIf	 
   
    aProd:={}
    _cTipCarga:=" "
    _nTotValor:=_nTotPall:=_nPesoTot:=0
    _cPaletFechado:="1-SIM"//PREENCHIDA DENTRO DA FUNÇÃO MOMS66CT(
    If SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

         _cTipCarga:=Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_TIPCAR")

       If MV_PAR10 = 1// CARGA REFRIGERADA
          If _cTipCarga <> "000002" // CARGA SECA
             (_cAlias2)->(DBSkip())
             Loop
          EndIf
       ElseIf MV_PAR10 = 2// CARGA SECA
          If _cTipCarga == "000002" // CARGA REFRIGERADA
             (_cAlias2)->(DBSkip())
             Loop
          EndIf
       EndIf

       M->C5_I_TIPCA :="2-Batida" // _nPosTPCA
       If SC5->C5_I_TIPCA = "1" .Or. SC5->C5_I_LOCEM $ "SP50/PR50/PR51" //Local QUE SÓ VENDE PALITAZADOS
          M->C5_I_TIPCA :="1-Paletizada"
       ElseIf !SC5->C5_I_TIPCA = "1/2"
          SA1->(DBSetOrder(1))                         
          If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
             If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
                 M->C5_I_TIPCA :="1-Paletizada"//PALETE CHEP
             Else
                 M->C5_I_TIPCA :="2-Batida"    //ESTIVADA
             EndIf   
          EndIf
          If SC5->C5_I_OPER == _cOper50 .Or. SC5->C5_I_OPER == _cOper51 //PEDIDO DE PALLET DEVE SER ENVIADO COMO ESTIVADO
             M->C5_I_TIPCA :="2-Batida"
          EndIf
       EndIf

       While SC6->(!Eof()) .And. SC6->C6_FILIAL == SC5->C5_FILIAL .And. SC6->C6_NUM == SC5->C5_NUM
            
            _nItemPall:=MOMS66CT(SC6->C6_PRODUTO,SC6->C6_QTDVEN,.F.,M->C5_I_TIPCA)//SC6->C6_I_QPALT //Pesquisar n MOMS66CT(
            _nTotPall +=_nItemPall
            //A funcao MOMS66CT() já posiciona no SB1

            aAdd(_aSC6_do_PV, { SC6->(RECNO()) ,;// RECNO 
                                           .T. ,;// SE TEM ESTOQUE
                                             0 ,;// (_nQtdeATend*_nfator)
                                             0 ,;// (_nQtdeFalta*_nfator)//QTDE FALTANTE
                                             0 ,;// _nPesoFalta
             (SB1->B1_PESBRU * SC6->C6_QTDVEN) ,;// Peso  por item
                                    _nItemPall })// Palet por item
            
            If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = 'S' 
               _nTotValor+=(SC6->C6_QTDVEN * SC6->C6_PRCVEN)
            EndIf

            SC6->(DBSkip())
       EndDo
    Else
       (_cAlias2)->(DBSkip())
       Loop
    EndIf
    nSalvaRecSC5:=SC5->(RECNO())
    _nPesoTot:=SC5->C5_I_PESBR
    _nTotAuxPall:=_nTotPall//GUARDA O TOTAL DE PALETES DO PEDIDO ANTES DE SOMAR O PEDIDO VINCULADO PARA MOSTRA NA COLUNA DA TELA
    If !Empty(SC5->C5_I_PEVIN)//Soma os Paletes do pedido vinculado
       
       _cPedVinc:=SC5->C5_FILIAL+SC5->C5_I_PEVIN
       If SC5->(DBSeek(_cPedVinc))
          _nPesoTot+=SC5->C5_I_PESBR
       EndIf
       SC5->(DBGoTo(nSalvaRecSC5))
       If (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == SC5->C5_I_PEVIN } )) > 0//SE ACHOU NA LISTA GERAL DE VINCULADOS não precisa fazer o While de novo
       
          _nTotPall+=aPedVin[_nPos][6]
       
       ElseIf SC6->(DBSeek(_cPedVinc))
       
          While SC6->(!Eof()) .And. SC6->C6_FILIAL+SC6->C6_NUM == _cPedVinc
               
             _nItemPall:=MOMS66CT(SC6->C6_PRODUTO,SC6->C6_QTDVEN,.F.,M->C5_I_TIPCA)//SC6->C6_I_QPALT //Pesquisar n MOMS66CT(
             _nTotPall +=_nItemPall
             SC6->(DBSkip())
          EndDo
       
       EndIf
    EndIf
    SC5->(DBGoTo(nSalvaRecSC5))
    
    //Paletes Fechados ?
    _cCargaFechada:="2-NAO"
    If _cPaletFechado = "1-SIM" //PREENCHIDA DENTRO DA FUNÇÃO MOMS66CT(
       If INT(_nTotPall) = _nTotPall .And. StrZero(_nTotPall,2,0) $ _cMultPall
          _cCargaFechada:="1-SIM"
       ElseIf StrZero( Round((_nPesoTot/1000),0)  ,2,0) $ _cMultPeso 
          _cCargaFechada:="1-SIM"
       EndIf
    Else
       If StrZero( Round((_nPesoTot/1000),0)  ,2,0) $ _cMultPeso 
          _cCargaFechada:="1-SIM"
       EndIf
    EndIf
    
    _cTipoEntr := U_TipoEntrega(SC5->C5_I_AGEND)
    If SC5->C5_I_OPER="20"
       _cTipoEntr := "Transferencia"
    EndIf

    If _cTipCarga == "000002" // CARGA REFRIGERADA - _nPosTPDACA
       _cTipCarga :="Carga Refrigerada"
    Else// Carga Seca
       _cTipCarga :="Carga Seca"
    EndIf

   _cNomeCli  := SC5->C5_CLIENTE+"-"+SC5->C5_LOJACLI+"-"+SC5->C5_I_NOME
   _cMicroReg := Posicione("CC2",1,xFilial("CC2")+SA1->A1_EST+SA1->A1_COD_MUN,"CC2_I_MICR")
   If CC2->(FIELDPOS("CC2_I_MELO")) > 0
      _cMesoReg:= If(Empty(CC2->CC2_I_MELO),CC2->CC2_I_MESO,CC2->CC2_I_MELO)
   Else
      _cMesoReg:= CC2->CC2_I_MESO
   EndIf	
   _cMicroReg := AllTrim(Posicione("Z22",4,xFilial("Z22")+SA1->A1_EST+CC2->CC2_I_MESO+_cMicroReg,"Z22_NOME"))
    _cMesoReg  := AllTrim(Posicione("Z21",1,xFilial("Z21")+_cMesoReg,"Z21_NOME"))
   _cRegiao   := AllTrim(U_ITRegiaoBR(Z21->Z21_EST,_cMesoReg))

   If !Empty(SC5->C5_I_PEVIN)
       aAdd(aPedVin,{SC5->C5_NUM    ,;// 01 - PEDIDO DA COLUNA 1 com os dados deles abaixo
                     SC5->C5_I_PEVIN,;// 02 - PEDIDO DA COLUNA 2 VINCULADO
                     _cMesoReg      ,;// 03 - GUARDA A MESO   DO PEDIDO DA COLUNA 1 - CONTEUDO ALTERADO DEPOIS
                     _cRegiao       ,;// 04 - GUARDA A REGIAO DO PEDIDO DA COLUNA 1 - CONTEUDO TALVEZ ALTERADO DEPOIS P/ PASTA 1 OU 2
                     _cMesoReg      ,;// 05 - GUARDA A MESO   DO PEDIDO DA COLUNA 1 - CONTEUDO FIXO / SEM ALTERACAO
                     _nTotAuxPall   ,;// 06 - TotaL de Pallets doa pedidoa vinculados DO PEDIDO DA COLUNA 1
                     _cClassEnt     ,;// 07 - "1-TOP 1 NACIONAL" DO PEDIDO DA COLUNA 1
                     "Palete Fechado: "+_cPaletFechado ,;// 08 - Pallet Fechado ou não DO PEDIDO DA COLUNA 1
                     "Carga Fechada: "+_cCargaFechada ,;// 09 - Carga Fechada ou não DO PEDIDO DA COLUNA 1
                     M->C5_I_TIPCA  ,;// 10 - Tipo: 1-Paletizada ou 2-Batida DO PEDIDO DA COLUNA 1
                     SC5->C5_I_PESBR})// 11 - Peso total do pedido DO PEDIDO DA COLUNA 1 - Deicar por ultimo sempre
   EndIf

   If Empty(_cObs)//_cObs: Preenchido na funcao MOMS66Ord ()
      _cLegenda:="ENABLE"
   ElseIf _cObs = "D"//DEPOIS DE HOJE
      _cLegenda:="BR_BRANCO"
   Else //_cObs = "A"//ANTES DE HOJE
      _cLegenda:="BR_PRETO"
   EndIf

   aAdd(_aPedidos, {"LBNO"          ,;                     //
                    "LBNO"          ,;                     //
                    "   "           ,;                     //CARGA C1 C2 C3 ...
                    _cLegenda       ,;                     //_cObs: Preenchido na funcao MOMS66Ord ()
                    "DISABLE"       ,;                     // 
                    "DISABLE"       ,;                     //"UP3",;"DOWN3",;0,;//07 //Ordem Prioridade Comercial ( Pode Alterar )
                    SC5->C5_NUM     ,;                     //
                    SC5->C5_EMISSAO ,;                     //
                    M->C5_I_TIPCA   ,;                     //TIPO DE CARGA - _nPosTPCA
                    _cTipCarga      ,;                     //TIPO DA CARGA - _nPosTPDACA
                    _nTotAuxPall    ,;                     //_nPosPalete
                    SC5->C5_I_PESBR ,;                     //_nPosPesBru
                    (DATE()-SC5->C5_EMISSAO) ,;            //
                    SC5->C5_I_DTENT ,;                     //
                    _dDataCalculada ,;                     // 
                    _cTipoEntr      ,;                     //Tp Agend
                    0               ,;                     //Ordem Prioridade Tipo de Agendamento ( Gerada ) _nPosOrdem
                    _nTotValor      ,;                     //_nPosTotPed
                    0               ,;                     //PESO SEM ESTOQUE - _nPosPesEst
                    _cNomeCli       ,;                     //
                    Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND1,"A3_NOME") ,;
                    Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NOME") ,;
                    Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND3,"A3_NOME") ,;
                    SC5->C5_I_MUN   ,;                     //
                    _cMicroReg      ,;                     //
                    _cMesoReg       ,;                     //
                    SC5->C5_I_EST   ,;                     //
                    _cRegiao        ,;                     //
                    SC5->C5_I_OPER  ,;                     //
                    SC5->C5_TPFRETE ,;                     //
                    SC5->C5_I_PEVIN ,;                     //
                    _cObs           ,;                     //_cObs: Preenchido na funcao MOMS66Ord ()
                    SC5->C5_I_QTDA  ,;                     //
                    _nDias          ,;                     //_nPosDias
                    _cClassEnt      ,;                     // TOP 1 NACIONAL - _nPosClass
                    _cPaletFechado  ,;                     // _nPosPaFec
                    _cCargaFechada  ,;                     // _nPosCaFechada
                    _cChave         ,;                     //CHAVE DE PRIORIDADE  
                    {SC5->(RECNO()),_aSC6_do_PV,(_nCapacPes-_nPesSaldoIni),.F.,(_nCapacPal-_nPalSaldoIni)},;//** POSICAO FIXA NÃO POR NENHUM CAMPO DEPOIS DESSE **
                    .F.            })                      //** POSICAO FIXA NÃO POR NENHUM CAMPO DEPOIS DESSE **

    (_cAlias2)->(DBSkip())

EndDo

If Len(_aPedidos) = 0
   U_ITMsg("Nenhum pedido atendeu aos critérios de pendencias.",'Atenção!',,3) 
   Return "Loop"
EndIf

_cTotGeral:=AllTrim(Str(Len(_aPedidos)))

(_cAlias2)->(DBCloseArea())

/*------------------------------------------*\
| Estrutura do aHeader do MsNewGetDados      |
|--------------------------------------------|
| aHeader[01] - X3_TITULO  | Título          |
| aHeader[02] - X3_CAMPO   | Campo           |
| aHeader[03] - X3_PICTURE | Picture         |
| aHeader[04] - X3_TAMANHO | Tamanho         |
| aHeader[05] - X3_DECIMAL | Decimal         |
| aHeader[06] - X3_VALID   | Validação       |
| aHeader[07] - X3_USADO   | Usado           |
| aHeader[08] - X3_TIPO    | Tipo            |
| aHeader[09] - X3_F3      | F3              |
| aHeader[10] - X3_CONTEXT | Contexto (R,V)  |
| aHeader[11] -,X3_CBOX    | Combobox        |
| aHeader[12] -,X3_RELACAO | Inicial. Padrao |
| aHeader[13] -,X3_WHEN    | Habilita edicao |
| aHeader[14] -,X3_VISUAL  | Alteravel (A,V) |
| aHeader[15] -,X3_VLDUSER | Valid de User   |
| aHeader[16] -,X3_PICTVAR | Picture         |
| aHeader[17] -,X3_OBRIGAT | Obrigatorio     |
\*------------------------------------------*/

Private aHeaderP:={}
Private aColsP  :={}
                                                                                //ESSE X3_TIPO SÓ INFLUENCIA NA GERAÇÃO DO EXCEL EM DECIDIR A PICTURE DA COLUNA
                                                                                //NÃO INTERFERE E NÃO SEGUE O TIPO GRAVADO NA _aPedidos, É INDEPENDENTE NOS CASO DE "C" e "N"
//                          1          2            3   4 5       6          7        8       9           10    11       12         13         14          15        16             17
//aHeader,{AllTrim(SX3->X3_TITULO), X3_CAMPO   , PICT ,TA,D, AllwaysTrue(),  USADO,X3_TIPO,ARQUIVO,X3_CONTEXT,X3_CBOX,X3_RELACAO,X3_WHEN   ,X3_VISUAL ,X3_VLDUSER,X3_PICTVAR,X3_OBRIGAT
aAdd(aHeaderP,{"Suger."            ,"MARCA"     ,"@BMP",04,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})  // 
nPosOK :=Len(aHeaderP)                                
aAdd(aHeaderP,{"Logi.OK"          ,"MARCA2"    ,"@BMP",04,0,""                ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})  // 
nPosOK2:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Carga"             ,"CARGA"     ,"!!" ,02,0,""                ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})  // 
nPosC1 :=Len(aHeaderP)                                
aAdd(aHeaderP,{"Carregar"          ,"PO_OK"     ,"@BMP",05,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})  // 
nPosCar:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Estoque"           ,"ESTOQUE"   ,"@BMP",05,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})
_nPosEst:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Capacidade"        ,"CAPACIDA"  ,"@BMP",05,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."})
_nPosCap:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Pedido"            ,"PEDIDO"    ,"@!"  ,Len(SC5->C5_NUM),0,"" ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."}) //
_nPosPed:=Len(aHeaderP)//06                                
aAdd(aHeaderP,{"Dt Emissao"        ,"C5EMISSAO" ,"@D"  ,08,0,""               ,""  ,"D"    ,""     ,""        ,""     ,"CTOD('')",".F."})
_nPosEms:=Len(aHeaderP)//07                                
aAdd(aHeaderP,{"Tipo de Carga"     ,"TPDECARGA" ,"@!"  ,15,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTPCA :=Len(aHeaderP)//M->C5_I_TIPCA                                  
aAdd(aHeaderP,{"Tipo da Carga"     ,"CTIPCARGA" ,"@!"  ,15,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTPDACA :=Len(aHeaderP)//_cTipCarga                                  
aAdd(aHeaderP,{"Qtde Palete"       ,"QTDE_PALETE","@E 999,999.99"     ,09,2,"",""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})
_nPosPalete:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Peso Bruto"        ,"C5_I_PESBR","@E 999,999,999.9999",14,4,"",""  ,"N"    ,""     ,""        ,""     ,""        ,".F."})
_nPosPesBru:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Dias"              ,"DIAS_ATRASO",""   ,06,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosAtraso:=Len(aHeaderP)//07                                
aAdd(aHeaderP,{"Dt Entrega"        ,"C5I_DTENT"  ,"@D" ,08,0,""               ,""  ,"D"    ,""     ,""        ,""     ,"CTOD('')",".F."})
_nPosEnt:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Dt Necessidade"    ,"DT_NECESSI","@D"  ,08,0,""               ,""  ,"D"    ,""     ,""        ,""     ,"CTOD('')",".F."})
_nPosNes:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Tp Agend "         ,"TIPO_AGEND",""    ,15,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTpA:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Posicao"           ,"PO_ORDEMA" ,"9999",04,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".T."}) // //Chave Prioridade Tipo de Agendamento
_nPosOrdem:=Len(aHeaderP)//05                                
aAdd(aHeaderP,{"Total Pedido"      ,"TOT_PEDIDO","@E 999,999,999,999.99",01,0,"","","N"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTotPed:=Len(aHeaderP)//_nTotValor
aAdd(aHeaderP,{"Peso sem Estoque"  ,"PES_S_ESTO","@E 999,999,999.9999"  ,01,0,"","","N"    ,""     ,""        ,""     ,""        ,".F."})
_nPosPesEst:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Cliente"           ,"C5_CLIENTE","@!" ,040,0,""                ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosCli:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Vendedor"          ,"C5VEND1"   ,"@!" ,040,0,""                ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosVend:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Coordenador"       ,"C5_VEND2"  ,"@!" ,040,0,""                ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosCoor:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Gerente"           ,"C5_VEND3"  ,"@!" ,040,0,""                ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosGer:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Mucnicipio"        ,"C5_I_MUN"  ,"@!" ,Len(SC5->C5_I_MUN),0,"" ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosMun:=Len(aHeaderP)                                  
aAdd(aHeaderP,{"Microrregião"      ,"Z22_NOME"  ,"@!" ,Len(Z22->Z22_NOME),0,"" ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
aAdd(aHeaderP,{"Mesorregião"       ,"Z21_NOME"  ,"@!" ,Len(Z21->Z21_NOME),0,"" ,"" ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosMeso:=Len(aHeaderP)//_cMesoReg                                
aAdd(aHeaderP,{"UF"                ,"C5_I_EST"  ,"@!" ,002,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosUF:=Len(aHeaderP)
aAdd(aHeaderP,{"Região do Brasil"  ,"REGIAOBR"  ,"@!" ,015,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosRGBR:=Len(aHeaderP)//_cRegiao                                
aAdd(aHeaderP,{"Tp Operacao"       ,"C5_I_OPER" ,"@!" ,001,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTpO:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Tp Frete"          ,"C5_TPFRETE","@!" ,001,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosTpF:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Ped. Vinculado"   ,"C5_I_PEVIN","@!" ,Len(SC5->C5_NUM)+14,0,"",""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosPedVin=Len(aHeaderP)                                
aAdd(aHeaderP,{"Observacao"        ,"OBSERVAC"  ,"  " ,150,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosObs  :=Len(aHeaderP)                                
aAdd(aHeaderP,{"Qtd Reagend."      ,"C5_I_QTDA" ,"99" ,002,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosReg:=Len(aHeaderP)                                
aAdd(aHeaderP,{"T.T."              ,"DIAS"      ,"9999",004,0,""              ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosDias:=Len(aHeaderP)                                
aAdd(aHeaderP,{"Classif. Entrega"  ,"CLASENTREG","@!" ,020,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosClass:=Len(aHeaderP)//"1-TOP 1 NACIONAL" / _cClassEnt                                
aAdd(aHeaderP,{"Paletes Fechados?"  ,"CARGACOMPL","@!",005,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosPaFec:=Len(aHeaderP)//_cPaletFechado                                
aAdd(aHeaderP,{"Carga Fechada?"    ,"CARGAFECHA","@!" ,005,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosCaFechada:=Len(aHeaderP)//_cCargaFechada                                
aAdd(aHeaderP,{"Controle"          ,"CONTROLE"  ,"@!" ,050,0,""               ,""  ,"C"    ,""     ,""        ,""     ,""        ,".F."})
_nPosChave:=Len(aHeaderP)                                                        //ESSE TIPO SÓ INFLUENCIA NA GERAÇÃO DO EXCEL EM DECIDIR A PICTURE DA COLUNA
                                                                                 //NÃO INTERFERE E NÃO SEGUE O TIPO GRAVADO NA _aPedidos, É INDEPENDENTE NOS CASO DE "C" e "N"

_nPosRecnos:=(Len(aHeaderP)+1)//{SC5->(RECNO()),_aSC6_do_PV,(_nCapacPes-_nPesSaldoIni),.F.}

Private _nTotGerFin  := _nTotNaoGerFin := _nTotPonFat := _nToRPonFat := 0
Private _aGerentes   := {}
Private _aCortaItem  := {}//BOTAO "CORTAR PRODUTOS" 
Private _aCortaPed   := {}//BOTAO "CORTAR PRODUTOS" 
Private _aPedXProdSE := {}//BOTAO "PEDIDOS X PRODUTOS SEM ESTOQUE"

//DIVIDE OS PEDIDOS

_aPedTOP1:={}
_aPedCAFE:={}
_aPedFORA:={}
_aPedRGBR:={{},{},{},{},{}}// 5 - REGIOES
aFoders1:={}
aAdd(aFoders1,"Cargas Fechadas TOP1")        //Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa      
aAdd(aFoders1,"Cargas Fechadas")             //Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa 
aAdd(aFoders1,"Pedidos fora de padrão")
aAdd(aFoders1,"Cargas por Regioes")
_aTotPonFat :={}
aAdd(_aTotPonFat,{"TOTAL GERAL"         ,0})
aAdd(_aTotPonFat,{aFoders1[1]           ,0})//"Cargas Fechadas TOP1"
aAdd(_aTotPonFat,{aFoders1[2]           ,0})//"Cargas Fechadas"     
aAdd(_aTotPonFat,{aFoders1[3]           ,0})//"Pedidos fora de padrão"
aAdd(_aTotPonFat,{"Regiao Sudeste"      ,0})//Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
aAdd(_aTotPonFat,{"Regiao Sul"          ,0})//Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
aAdd(_aTotPonFat,{"Regiao Centro Oeste" ,0})//Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
aAdd(_aTotPonFat,{"Regiao Norte"        ,0})//Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa
aAdd(_aTotPonFat,{"Regiao Nordeste"     ,0})//Se mudar os nomes tem que mudar em todo o programa pq eles são chave de Pesquisa

aAdd(aFolderRGBR,"Regiao Centro Oeste" )
aAdd(aFolderRGBR,"Regiao Norte"        )
aAdd(aFolderRGBR,"Regiao Nordeste"     )
aAdd(aFolderRGBR,"Regiao Sudeste"      )
aAdd(aFolderRGBR,"Regiao Sul"          )
aFolderRGBR:= aSort(aFolderRGBR)//ATE 5 REGIOES 

_cTotGeral:=AllTrim(Str(Len(_aPedidos)))

If MV_PAR09 = 1 .And. SB2->(FIELDPOS("B2_I_QLIBE")) > 0 
   MOMS66CLB(_aPedidos,oProc)
EndIf

For P := 1 TO Len(_aPedidos) 
   
   nConta++
   oProc:cCaption := ("3-Separando os pedidos - "+StrZero(nConta,5) +" de "+ _cTotGeral )
   ProcessMessages()
    
    _nPesoAux:=_aPedidos[P,_nPosPesBru]
    If !Empty(_aPedidos[P,_nPosPedVin]) .And. (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPed] } )) > 0
       _nPesoAux+=aPedVin[_nPos][ Len(aPedVin[_nPos]) ]
    EndIf

    If _aPedidos[P,_nPosClass] == "1-TOP 1 NACIONAL" .And. _aPedidos[P,_nPosCaFechada] == "1-SIM" // _cClassEnt
       aAdd(_aPedTOP1,_aPedidos[P])           //TOP 1 NACIONAL e CARGA FECHADA
       
       If !Empty(_aPedidos[P,_nPosPedVin]) .And. (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPed] } )) > 0
           aPedVin[_nPos,3]:=aFoders1[1]+" ("+_aPedidos[P,_nPosRGBR]+" /"+_aPedidos[P,_nPosMeso]+")"
           aPedVin[_nPos,4]:=aFoders1[1]      //"Cargas Fechadas TOP1"
       EndIf
    
    ElseIf _aPedidos[P,_nPosCaFechada] == "1-SIM" 
       aAdd(_aPedCAFE,_aPedidos[P])           //CARGA FECHADA

       If !Empty(_aPedidos[P,_nPosPedVin]) .And. (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPed] } )) > 0
           aPedVin[_nPos,3]:=aFoders1[2]+" ("+_aPedidos[P,_nPosRGBR]+" /"+AllTrim(_aPedidos[P,_nPosMeso]) + ")"
           aPedVin[_nPos,4]:=aFoders1[2]//"Cargas Fechadas"
       EndIf

    ElseIf _nPesoAux > _nPesoMax
       aAdd(_aPedFORA,_aPedidos[P])           //"Pedidos fora de padrão"

       If !Empty(_aPedidos[P,_nPosPedVin]) .And. (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPed] } )) > 0
           aPedVin[_nPos,3]:=aFoders1[3]+" ("+_aPedidos[P,_nPosRGBR]+" /"+AllTrim(_aPedidos[P,_nPosMeso]) + ")"
           aPedVin[_nPos,4]:=aFoders1[3]      //"Pedidos fora de padrão"
       EndIf

    ElseIf _aPedidos[P,_nPosCaFechada] <> "1-SIM" //CARGA NAO FECHADA

       If !Empty(_aPedidos[P,_nPosPedVin]) .And. (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPed] } )) > 0
           aPedVin[_nPos,3]:=_aPedidos[P,_nPosRGBR]+ " / "+_aPedidos[P,_nPosMeso]//+" / "+AllTrim(aPedVin[_nPos,3]) 
       EndIf

       If (nPosR:=aScan(aFolderRGBR,_aPedidos[P,_nPosRGBR] )) > 0 //PROCURA A REGIAO PARA POR NA POSICAO CERTA A MESO
           aAdd(_aPedRGBR[nPosR], { _aPedidos[P,_nPosMeso] , _aPedidos[P] , _aPedidos[P,_nPosRGBR] })
       EndIf
    
    EndIf
Next

oProc:cCaption := ("4-Analisando Pedidos TOP 1..." )
ProcessMessages()
_aSB2Inic:= {} 
_lSomaPontFat:=.T.//LIGA AQUI A SOMA PARA NA CARGA INICIAL

_aPedTOP1:=MOMS66PVinc(_aPedTOP1)              // ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
_aPedTOP1:=MOMS66PC(_aPedTOP1,"TODOS",.T.,.F.,,aFoders1[1]) //ZERA A ARRAY _aSB2 NO PRIMEIRO PARA LER O ESTOQUE OFICIAL// VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////

oProc:cCaption := ("5-Analisando Pedidos Carga fechada..." )
ProcessMessages()

_aPedCAFE:=MOMS66PVinc(_aPedCAFE)              // ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
_aPedCAFE:=MOMS66PC(_aPedCAFE,"TODOS",.F.,.F.,,aFoders1[2]) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////

oProc:cCaption := ("5-Analisando Pedidos fora de padrão..." )
ProcessMessages()

_aSB2:=MOMS66aSB2(_aSB2,"SALVA")//Salva estoque antes de processar as Regioes
_nBKPPesoLib  := _nTotPesoLib   //Salva totais antes de processar as Regioes
_nBKPPalsLib  := _nTotPalsLib   //Salva totais antes de processar as Regioes
_nBKPGerFin   := _nTotGerFin    //Salva totais antes de processar as Regioes
_nBKPNaoGerFin:= _nTotNaoGerFin //Salva totais antes de processar as Regioes

_aPedFORA:=MOMS66PVinc(_aPedFORA)              // ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
_aPedFORA:=MOMS66PC(_aPedFORA,"TODOS",.F.,.T.,,aFoders1[3]) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////

_nTot:=Len(_aPedRGBR) 
P:=1
DO  While P <= _nTot 
    If Len(_aPedRGBR[P]) = 0
       aDEL(aFolderRGBR,P)
       aSIZE(aFolderRGBR,Len(aFolderRGBR)-1)
       aDEL(_aPedRGBR,P)
       aSIZE(_aPedRGBR,Len(_aPedRGBR)-1)
       _nTot:=Len(_aPedRGBR) 
    Else
       P++
    EndIf
EndDo
If _nTot = 0
  aDEL(aFoders1,4)
  aSIZE(aFoders1,3)
EndIf

aPedsReg1:={}//Array com todos os Pedidos das mesos da Regiao 1
aPedsReg2:={}//Array com todos os Pedidos das mesos da Regiao 2
aPedsReg3:={}//Array com todos os Pedidos das mesos da Regiao 3
aPedsReg4:={}//Array com todos os Pedidos das mesos da Regiao 4
aPedsReg5:={}//Array com todos os Pedidos das mesos da Regiao 5

aFoldReg1:={}//Array com todos os nomes das mesos da Regiao 1
aFoldReg2:={}//Array com todos os nomes das mesos da Regiao 2
aFoldReg3:={}//Array com todos os nomes das mesos da Regiao 3
aFoldReg4:={}//Array com todos os nomes das mesos da Regiao 4
aFoldReg5:={}//Array com todos os nomes das mesos da Regiao 5
_cTotGeral:=AllTrim(Str(Len(_aPedRGBR)))
For P := 1 TO Len(_aPedRGBR) //LENDO AS 5 REGIOES

    If P <= Len(aFolderRGBR)
       oProc:cCaption := ("6-Analisando "+aFolderRGBR[P]+" - "+StrZero(P,1) +" de "+ _cTotGeral )
       ProcessMessages()
    EndIf

    _aPedPasta:=_aPedRGBR[P]
    If Len(_aPedPasta) = 0
       Loop
    EndIf
    _aPedPasta:=aSort( _aPedPasta, , , {|X,Y| X[1] < Y[1] } )//POR MESO
    _cMesoReg:=AllTrim(_aPedPasta[1,1])
    If P = 1 
        aAdd(aFoldReg1,_cMesoReg)//PRIMEIRA NOME AQUI 
    ElseIf P = 2
        aAdd(aFoldReg2,_cMesoReg)//PRIMEIRA NOME AQUI 
    ElseIf P = 3
        aAdd(aFoldReg3,_cMesoReg)//PRIMEIRA NOME AQUI 
    ElseIf P = 4
        aAdd(aFoldReg4,_cMesoReg)//PRIMEIRA NOME AQUI 
    ElseIf P = 5
        aAdd(aFoldReg5,_cMesoReg)//PRIMEIRA NOME AQUI 
    EndIf
    aMesoAux:={}
    For M := 1 TO Len(_aPedPasta) //LENDO AS MESO DE CADA REGIAO
        If AllTrim(_aPedPasta[M,1]) == _cMesoReg
          aAdd(aMesoAux,_aPedPasta[M,2])
        Else
          _cMesoReg := AllTrim(_aPedPasta[M,1])
          If P = 1 
              aAdd(aPedsReg1,aMesoAux)   
              aAdd(aFoldReg1,_cMesoReg)//SEGUNDO EM DIANTE NOME AQUI 
          ElseIf P = 2
              aAdd(aPedsReg2,aMesoAux)   
              aAdd(aFoldReg2,_cMesoReg)//SEGUNDO EM DIANTE NOME AQUI 
          ElseIf P = 3
              aAdd(aPedsReg3,aMesoAux)   
              aAdd(aFoldReg3,_cMesoReg)//SEGUNDO EM DIANTE NOME AQUI 
          ElseIf P = 4
              aAdd(aPedsReg4,aMesoAux)   
              aAdd(aFoldReg4,_cMesoReg)//SEGUNDO EM DIANTE NOME AQUI 
          ElseIf P = 5
              aAdd(aPedsReg5,aMesoAux)   
              aAdd(aFoldReg5,_cMesoReg)//SEGUNDO EM DIANTE NOME AQUI 
          EndIf
          aMesoAux:={}
          aAdd(aMesoAux,_aPedPasta[M,2])
       EndIf
    Next
    If P = 1 
       aAdd(aPedsReg1,aMesoAux)   
    ElseIf P = 2
       aAdd(aPedsReg2,aMesoAux)   
    ElseIf P = 3
       aAdd(aPedsReg3,aMesoAux)   
    ElseIf P = 4
       aAdd(aPedsReg4,aMesoAux)   
    ElseIf P = 5
       aAdd(aPedsReg5,aMesoAux)   
    EndIf
Next

For P := 1 TO Len(aPedsReg1) //LENDO AS REGIOES
    _aPedPasta:=aPedsReg1[P]
    aPedsReg1[P]:=MOMS66PVinc(_aPedPasta)       //// ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
    aPedsReg1[P]:=MOMS66PC(aPedsReg1[P],"TODOS",.F.,.T.) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////
Next
For P := 1 TO Len(aPedsReg2) //LENDO AS REGIOES
    _aPedPasta:=aPedsReg2[P]
    aPedsReg2[P]:=MOMS66PVinc(_aPedPasta)       //// ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
    aPedsReg2[P]:=MOMS66PC(aPedsReg2[P],"TODOS",.F.,.T.) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////
Next
For P := 1 TO Len(aPedsReg3) //LENDO AS REGIOES
    _aPedPasta:=aPedsReg3[P]
    aPedsReg3[P]:=MOMS66PVinc(_aPedPasta)       //// ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
    aPedsReg3[P]:=MOMS66PC(aPedsReg3[P],"TODOS",.F.,.T.) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////
Next
For P := 1 TO Len(aPedsReg4) //LENDO AS REGIOES
    _aPedPasta:=aPedsReg4[P]
    aPedsReg4[P]:=MOMS66PVinc(_aPedPasta)       //// ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
    aPedsReg4[P]:=MOMS66PC(aPedsReg4[P],"TODOS",.F.,.T.) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////
Next
For P := 1 TO Len(aPedsReg5) //LENDO AS REGIOES
    _aPedPasta:=aPedsReg5[P]
    aPedsReg5[P]:=MOMS66PVinc(_aPedPasta)       //// ANALIZA OS PEDIDOS VINCULADOS E MARCA A ORDEM DE CONSUMO DO ESTOQUE
    aPedsReg5[P]:=MOMS66PC(aPedsReg5[P],"TODOS",.F.,.T.) // VERIFICANDO ESTOQUE E CAPACIDADE DA UNIDADE PROCESSAMENTO PRINCIPAL  ////
Next

_lSomaPontFat:=.F.//DESLIGA A SOMA PARA FRENTE

oProc:cCaption := ("Montando Pastas..." )
ProcessMessages()

_aSB2:=MOMS66aSB2(_aSB2,"VOLTA")//RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
_nTotPesoLib  := _nBKPPesoLib   //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
_nTotPalsLib  := _nBKPPalsLib   //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
_nTotGerFin   := _nBKPGerFin    //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
_nTotNaoGerFin:= _nBKPNaoGerFin //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 

If Len(_aPedidos) > 0 
   
   Private _aSize := MsAdvSize()
   Private _aInfo := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 3 , 3 }
   
   // pega tamanhos das telas
   aObjects := {}
   aAdd( aObjects , { 100 , 050 , .T. , .F. , .F. } )
   aAdd( aObjects , { 100 , 100 , .T. , .T. , .F. } )
   aPosObj  := MsObjSize( _aInfo , aObjects )
   nNext    := 0
   nOpca    := 0
   nGDAction:= GD_UPDATE

   aColsP := _aPedidos//SEM ACLONE PQ SE MEXER NO ACOLS TEM QUE MEXE NO _APEDIDOS  ******************************************

   bReprocessa:={|| If(U_ITMsg("Confirma REPROCESSAMENTO ?",'Atenção!',,2,2,2),(_lReprocessar:=.T.,oDlg2:End()),) }
   _bEfetivar :={|| If(MOMS66Acesso(_lEfetivar) .AND.;
                    U_ITMsg("Confirma EFETIVACAO / GRAVACAO ?",'EFETIVACAO / GRAVACAO!',"ATENÇÃO: Cargas não validadas nas Mesorregiões não serão liberadas.",2,2,2),(_lGrava:=.T.,oDlg2:End()),) }
   _bSair     :={|| (_lGrava:=.F.,oDlg2:End())  }
   _bSimular  :={|| If(MOMS66Acesso(_lEfetivar) .AND.;
                    U_ITMsg("Confirma SIMULACAO / GRAVACAO ?",'SIMULACAO / GRAVACAO!',,2,2,2),(_lSimular:=.T.,oDlg2:End()),) }

   aBotoes:={} 
   aAdd(aBotoes,{"",bReprocessa         ,"","REPROCESSAR"}) 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66Pesq()              },"Pesquisando.."         ,"H.I. : "+TIME()+" - Aguarde..." )},"","PESQUISAR"                 }) //
   aAdd(aBotoes,{"",_bSimular                                     ,"","SIMULACAO"})            
   aAdd(aBotoes,{"",{|| MOMS66Alt(.T.)                           },"","Desvincula Pedidos"  })    																  // 
   aAdd(aBotoes,{"",{|| MOMS66Alt(.F.)                           },"","CORTAR PRODUTOS"     })    																  // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66Item("PEDXPRODSEST")},"Lendo Itens.."         ,"H.I. : "+TIME()+" - Aguarde...")},"","Pedidos X Prod. sem Estoque"}) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66Item("ITENS"       )},"Lendo Itens.."         ,"H.I. : "+TIME()+" - Aguarde...")},"","VER / CORTAR Itens Pedido"  }) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66Item("CONSOLIDADO" )},"Lendo Itens.."         ,"H.I. : "+TIME()+" - Aguarde...")},"","SALDO CONSOLIDADO"          }) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66PPV("S")            },"Lendo Pedidos.."       ,"H.I. : "+TIME()+" - Aguarde...")},"","Ver Pedido Monitor"         }) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66PPV("D")            },"Lendo Pedidos.."       ,"H.I. : "+TIME()+" - Aguarde...")},"","Ver Pedido Detalhado"       }) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("DETI",O,)   },"Lendo Pedidos.."       ,"H.I. : "+TIME()+" - Aguarde...")},"","Detalhamento por Itens"     }) // 
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("XLSX",O,)   },"Gerando Excel (XLSX)..","H.I. : "+TIME()+" - Aguarde...")},"","Exportacao para XLSX"       }) //  
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("XML" ,O,)   },"Gerando Excel (XML).. ","H.I. : "+TIME()+" - Aguarde...")},"","Exportacao para XML "       }) // 
   If !(GetRemoteType() == 5) //Valida se o ambiente é Protheus via HTML           
   aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("CSV" ,O,)   },"Gerando Excel (CSV).. ","H.I. : "+TIME()+" - Aguarde...")},"","Exportacao para CSV "       }) //
   EndIf
   aAdd(aBotoes,{"",{|| MOMS66LEG(.F.) },"","Legendas"   }) 
   
   While .T.

      _lReprocessar:=.F.
      _lGrava:=.F.
      _lSimular:=.F.
      nLin01:=05
      nLin02:=08 
      nLin03:=25 
      nCol01:=02
      aBrowses:={}
      oTFolder01:=NIL
   
      DEFINE MSDIALOG oDlg2 TITLE _cTitulo OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]

      //PARTE DE CIMA DA TELA PRINCIPAL
                                                        //Largura , ALTURA
       oPnlTopTop := TPanel():New( 1 , 0 , , oDlg2 , , , , , , 80 , 20 , .F. , .F. )   

       oMenu:=TMenu():New(0,0,0,0,.T.)  
       _aMenu:={}
       For P := 1 TO Len(aBotoes)
           aAdd( _aMenu , TMenuItem():New(oMenu,aBotoes[P,4],,,,aBotoes[P,2],,,,,,,,,.T.) )
           oMenu:Add(_aMenu[P])
       Next

       @ nLin01, nCol01 BUTTON oBtMenu PROMPT  "AÇÕES"       SIZE 045, 013 OF oPnlTopTop ACTION EVAL( .T. ) PIXEL
       oBtMenu:SetPopupMenu(oMenu)
       nCol01+=49
       
       @ nLin01, nCol01 BUTTON  "GERAR"          SIZE 030, 013 OF oPnlTopTop ACTION EVAL( _bEfetivar  ) PIXEL
       nCol01+=35
       
       @ nLin01, nCol01 BUTTON  "SAIR"           SIZE 025, 013 OF oPnlTopTop ACTION EVAL( _bSair      ) PIXEL
       nCol01+=30	   

          @ nLin02-5,nCol01 Say "Saldo Inicial: " +("KG "+AllTrim(TRANS(_nPesSaldoIni,"@E 999,999,999,999.999"))) SIZE 099,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say "Qtde de Palete: "+(AllTrim(TRANS(_nPalSaldoIni,"@E 999,999,999,999.999")))       SIZE 099,009 OF oPnlTopTop PIXEL 	   
       nCol01+=(35+55)
          
       @ nLin02-5,nCol01 Say oSAYPesLib PROMPT "A Liberar: "+("KG "+AllTrim(TRANS( _nTotPesoLib,"@E 999,999,999,999.999"))) SIZE 099,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say oSAYPalLib PROMPT "Qtde Palete: "+(AllTrim(TRANS( _nTotPalsLib,"@E 999,999,999,999.999")))     SIZE 099,009 OF oPnlTopTop PIXEL 
       nCol01+=(24+55)
       
          @ nLin02-5,nCol01 Say "Capacidade UN: " +("KG "+AllTrim(TRANS(_nCapacPes,"@E 999,999,999,999"))) SIZE 199,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say "Qtde de Palete: "+(AllTrim(TRANS(_nCapacPal,"@E 999,999,999,999")))       SIZE 199,009 OF oPnlTopTop PIXEL 
       nCol01+=(38+55)

          @ nLin02-5,nCol01 Say oSAYVlGer   PROMPT "Valor Gera Financeiro: "   +("R$ "+AllTrim(TRANS( _nTotGerFin  ,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say oSAYPesNGer PROMPT "Peso Não Gera Financeiro.:"+("KG "+AllTrim(TRANS(_nTotNaoGerFin,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 
       nCol01+=(55+55)

          @ nLin02-5,nCol01 Say oSAYToPon   PROMPT "Potencial Faturamento Geral: "               +("R$ "+AllTrim(TRANS( _nTotPonFat,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say oSAYRTotPon PROMPT "Potencial Faturamento "+AllTrim(cPastaR)+": "+("R$ "+AllTrim(TRANS( _nToRPonFat,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 

       //FOLDER PRINCIPAL COM 3 PASTAS
       _nColFolder:=aPosObj[2,4]//350
       _nLinFolder:=aPosObj[2,3]-10//100

       oTFolder01:= TFolder():New( nLin03,1,aFoders1,,oDlg2,,,,.T., , _nColFolder,_nLinFolder )
       oTFolder01:bChange    :={|| MOMS66Atu("P1") }	   

       oPastaTOP1:=oTFolder01:aDialogs[1] // "CARGAS FECHADAS TOP1
        
       oBrwTOP1:=MOMS66Brw(aHeaderP,_aPedTOP1,oPastaTOP1)

       oPastaCaFe:=oTFolder01:aDialogs[2]   // CARGAS FECHADAS

       oBrwCaFe:=MOMS66Brw(aHeaderP,_aPedCAFE,oPastaCaFe)

       oPastaFORA:=oTFolder01:aDialogs[3]   // Pedidos Fora de Padrão

       oBrwFORA:=MOMS66Brw(aHeaderP,_aPedFORA,oPastaFORA)
       
       If Len(aFoders1) > 3 
          oPastaCaRe := oTFolder01:aDialogs[4] // CARGAS POR REGIOES DO BRASIL
       EndIf

       oPnlBoton:= TPanel():New( 1 , 0 , , oDlg2 , , , , , , 80 , 20 , .F. , .F. )   
       oPnlBoton:Align := CONTROL_ALIGN_BOTTOM
      
       _nRMesoPesoLib  :=0
       _nVMesoPesoLib  :=0
       _nRMesoPalsLib  :=0
       _nVMesoPalsLib  :=0
       _nRMesoValor    :=0
       _nVMesoValor    :=0
       _nRMesoNaoGerFin:=0
       _nMesoPonFat    :=0
       nMesoPonPeso    :=0
       _cRQtdeCarrega  :=" "
       nCol01:=2
          nLin01:=6
       lRegioes:=.F.//ATUALIZADO DENTRO DA MOMS66Obj ()
       cPastaR :="" //ATUALIZADO DENTRO DA MOMS66Obj ()

       @ nLin01-2, nCol01 BUTTON oBotValCar PROMPT "VALIDA CARGA"  SIZE 050, 012 OF oPnlBoton ACTION ( MOMS66VCarga() ) PIXEL 
       nCol01+=55
       
          @ nLin01-4,nCol01 Say oSAYRPeso  PROMPT "A Liberar Marcado : "+("KG "+AllTrim(TRANS( _nRMesoPesoLib,"@E 999,999,999,999.999")))             SIZE 200,009 OF oPnlBoton PIXEL 
          @ nLin01+5,nCol01 Say oSAYVPeso  PROMPT "A Liberar Sugerido: "+("KG "+AllTrim(TRANS( _nVMesoPesoLib,"@E 999,999,999,999.999")))             SIZE 200,009 OF oPnlBoton PIXEL 
       nCol01+=95        
          @ nLin01-4,nCol01 Say oSAYRPale  PROMPT "Qtde Palete Marcado : "+(AllTrim(TRANS( _nRMesoPalsLib,"@E 999,999,999,999.99")))                  SIZE 200,009 OF oPnlBoton PIXEL 
          @ nLin01+5,nCol01 Say oSAYVPale  PROMPT "Qtde Palete Sugerido: "+(AllTrim(TRANS( _nVMesoPalsLib,"@E 999,999,999,999.99")))                  SIZE 200,009 OF oPnlBoton PIXEL 
       nCol01+=95        
          @ nLin01-4,nCol01 Say oSAYRVGerF PROMPT "Valor Gera Financeiro Marcado : "+(AllTrim(TRANS( _nRMesoValor,"@E 999,999,999,999.99")))          SIZE 200,009 OF oPnlBoton PIXEL 
          @ nLin01+5,nCol01 Say oSAYVVGerF PROMPT "Valor Gera Financeiro Sugerido: "+(AllTrim(TRANS( _nVMesoValor,"@E 999,999,999,999.99")))          SIZE 200,009 OF oPnlBoton PIXEL 
       nCol01+=125
          @ nLin01-4,nCol01 Say oSAYRPnGer PROMPT "Peso não Gera Financeiro Marcado: "+(AllTrim(TRANS( _nRMesoNaoGerFin ,"@E 999,999,999,999.999")))  SIZE 200,009 OF oPnlBoton PIXEL 
          @ nLin01+5,nCol01 Say oSAYVPnGer PROMPT "Potencial Fat.: R$ "+AllTrim(TRANS(_nMesoPonFat,"@E 999,999,999,999.99"))+" - KG "+AllTrim(TRANS(nMesoPonPeso,"@E 999,999,999,999.099"))   SIZE 200,009 OF oPnlBoton PIXEL 
       nCol01+=136
          @ nLin01-4,nCol01 Say oSAYNPastA PROMPT "Pasta Ativa "+Capital(MOMS66Obj(.T.)[1])                                                           SIZE 200,009 OF oPnlBoton PIXEL 
          @ nLin01+5,nCol01 Say oSAYValCar PROMPT "Qtde Carrgamento: "+_cRQtdeCarrega                                                                 SIZE 200,009 OF oPnlBoton PIXEL 

       //FOLDER 4 DAS REGIOES DO BRASIL COM ATE 5 PASTAS
       _nLinFolder:=(_nLinFolder-15)

       If Len(aFoders1) > 3 
          oPastaRegs:= TFolder():New( 0 , 1 ,aFolderRGBR,,oPastaCaRe,,,,.T., , _nColFolder,_nLinFolder )   
          oPastaRegs:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastaRegs:bChange   :={|| MOMS66Atu("RB") }	
       Else
          oPastaRegs:=NIL   
       EndIf

       _nLinFolder:=(_nLinFolder-85)

       If Len(aFoldReg1) > 0 // CARGAS POR MESO DA REGIAO 1
          oProc:cCaption := ("1/5 - Montando Pasta: "+aFolderRGBR[1] )
          ProcessMessages()
          oPastaR1  := oPastaRegs:aDialogs[1] 
          oPastMeso1:= TFolder():New( 1 , 1 ,aFoldReg1,,oPastaR1,,,,.T., , _nColFolder,_nLinFolder )   
          oPastMeso1:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastMeso1:bChange   :={|| MOMS66Atu("R1") }	   
          For P := 1 TO Len(aFoldReg1)
              oBrwMeso1:=MOMS66Brw(aHeaderP,aPedsReg1[P],oPastMeso1:aDialogs[P])
              oBrwMeso1:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT
          Next
       EndIf	  
       If Len(aFoldReg2) > 0 // CARGAS POR MESO DA REGIAO 2
          oProc:cCaption := ("2/5 - Montando Pasta: "+aFolderRGBR[2] )
          oPastaR2  := oPastaRegs:aDialogs[2] 
          oPastMeso2:= TFolder():New( 1 , 1 ,aFoldReg2,,oPastaR2,,,,.T., , _nColFolder,_nLinFolder )   
          oPastMeso2:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastMeso2:bChange   :={|| MOMS66Atu("R2") }	   
          For P := 1 TO Len(aFoldReg2)
              oBrwMeso2:=MOMS66Brw(aHeaderP,aPedsReg2[P],oPastMeso2:aDialogs[P])
              oBrwMeso2:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT
          Next
       EndIf	  
       If Len(aFoldReg3) > 0 // CARGAS POR MESO DA REGIAO 3
          oProc:cCaption := ("3/5 - Montando Pasta: "+aFolderRGBR[3] )
          oPastaR3  := oPastaRegs:aDialogs[3] 
          oPastMeso3:= TFolder():New( 1 , 1 ,aFoldReg3,,oPastaR3,,,,.T., , _nColFolder,_nLinFolder )   
          oPastMeso3:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastMeso3:bChange   :={|| MOMS66Atu("R3") }	   
          For P := 1 TO Len(aFoldReg3)
              oBrwMeso3:=MOMS66Brw(aHeaderP,aPedsReg3[P],oPastMeso3:aDialogs[P])
              oBrwMeso3:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT
          Next
       EndIf	  
       If Len(aFoldReg4) > 0 // CARGAS POR MESO DA REGIAO 4
          oProc:cCaption := ("4/5 - Montando Pasta: "+aFolderRGBR[4] )
          oPastaR4  := oPastaRegs:aDialogs[4] 
          oPastMeso4:= TFolder():New( 1 , 1 ,aFoldReg4,,oPastaR4,,,,.T., , _nColFolder,_nLinFolder )   
          oPastMeso4:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastMeso4:bChange   :={|| MOMS66Atu("R4") }	   
          For P := 1 TO Len(aFoldReg4)
              oBrwMeso4:=MOMS66Brw(aHeaderP,aPedsReg4[P],oPastMeso4:aDialogs[P])
              oBrwMeso4:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT
          Next
       EndIf	  
       If Len(aFoldReg5) > 0 // CARGAS POR MESO DA REGIAO 5
          oProc:cCaption := ("5/5 - Montando Pasta: "+aFolderRGBR[5] )
          oPastaR5  := oPastaRegs:aDialogs[5] 
          oPastMeso5:= TFolder():New( 1 , 1 ,aFoldReg5,,oPastaR5,,,,.T., , _nColFolder,_nLinFolder )   
          oPastMeso5:Align:=CONTROL_ALIGN_ALLCLIENT
          oPastMeso5:bChange   :={|| MOMS66Atu("R5") }	   
          For P := 1 TO Len(aFoldReg5)
              oBrwMeso5:=MOMS66Brw(aHeaderP,aPedsReg5[P],oPastMeso5:aDialogs[P])
              oBrwMeso5:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT
          Next
       EndIf

       oDlg2:lMaximized:=.T.
       
       MOMS66Atu("INICIO")//PRIMEIRA CARGA DA TELA
          
      ACTIVATE MSDIALOG oDlg2 ON INIT (oPnlTopTop:Align:= CONTROL_ALIGN_TOP                          ,;// TELA PRINCIPAL
                                       oTFolder01:Align:= CONTROL_ALIGN_ALLCLIENT                    ,;// TELA PRINCIPAL
                                       oPnlBoton:Align := CONTROL_ALIGN_BOTTOM                       ,;// PAINEL DE TOTAIS SUGERIDOS 
                                       If(oPastaRegs<>NIL,oPastaRegs:Align:=CONTROL_ALIGN_ALLCLIENT,),;// PASTA DAS 5 REGIOES DO BRASIL
                                       oBrwCaFe:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT               ,;// PASTA CARGAS FECHADAS
                                       oBrwFORA:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT               ,;// PASTA PEDIDOS FORA DE PADRÃO
                                          oBrwTOP1:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT                )// PASTA CARGAS FECHADAS TOP1
      If _lReprocessar 
         
         FWMsgRun( ,{|oProc| MOMS66Reproc(oProc) },"Reprocessando todos os Pedidos...","Aguarde...")

      ElseIf _lGrava .Or. _lSimular

         FWMsgRun( ,{|oProc| MOMS66Proc(oProc) },"Processando todos os Pedidos...","Aguarde...")
         Return "SAIR" 
   
      ElseIf U_ITMsg("Confirma SAIR ?",'Atenção!',"Todas as alterações serão predidas!",3,2,2)
         
         Exit
   
      EndIf

   EndDo

EndIf

Return "Loop"

/*
===============================================================================================================================
Programa--------: MOMS66Brw
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2024
Descrição-------: Cria os blowses
Parametros------: aHeaderP,_aColsP,oPasta
Retorno---------: oMsMGet
===============================================================================================================================*/
Static Function MOMS66Brw(aHeaderP,_aColsP,oPasta)

Local oMsMGet

If Len(_aColsP) > 0
   nGDAction:= GD_UPDATE
Else
   nGDAction:= GD_INSERT
EndIf
/*------------------------------------------*\
| Estrutura do aHeader do MsNewGetDados      |
|--------------------------------------------|
| aHeader[01] - X3_TITULO  | Título          |
| aHeader[02] - X3_CAMPO   | Campo           |
| aHeader[03] - X3_PICTURE | Picture         |
| aHeader[04] - X3_TAMANHO | Tamanho         |
| aHeader[05] - X3_DECIMAL | Decimal         |
| aHeader[06] - X3_VALID   | Validação       |
| aHeader[07] - X3_USADO   | Usado           |
| aHeader[08] - X3_TIPO    | Tipo            |
| aHeader[09] - X3_F3      | F3              |
| aHeader[10] - X3_CONTEXT | Contexto (R,V)  |
| aHeader[11] - X3_CBOX    | Combobox        |
| aHeader[12] - X3_RELACAO | Inicial. Padrao |
| aHeader[13] - X3_WHEN    | Habilita edicao |
| aHeader[14] - X3_VISUAL  | Alteravel (A,V) |
| aHeader[15] - X3_VLDUSER | Valid de User   |
| aHeader[16] - X3_PICTVAR | Picture         |
| aHeader[17] - X3_OBRIGAT | Obrigatorio     |
\*------------------------------------------*/
                             //[ nTop]          , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter]                                              , [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] 
oMsMGet := MsNewGetDados():New((aPosObj[2,1]+12),aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],nGDAction ,        ,       ,        ,{"MARCA","MARCA2","PO_OK","ESTOQUE","CAPACIDA","PEDIDO"},           ,        ,            ,             ,          ,oPasta  ,aHeaderP        , _aColsP   ,)
oMsMGet:SetEditLine(.F.)
oMsMGet:AddAction("MARCA"    ,{|| MOMS662CLIK() }) // LEGENDAS
oMsMGet:AddAction("MARCA2"   ,{|| MOMS662CLIK() }) // LEGENDAS
oMsMGet:AddAction("PO_OK"    ,{|| MOMS662CLIK() }) // LEGENDAS
oMsMGet:AddAction("ESTOQUE"  ,{|| MOMS662CLIK() }) // ITENS DOS PEDIDOS
oMsMGet:AddAction("CAPACIDA" ,{|| MOMS662CLIK() }) // LEGENDAS
oMsMGet:AddAction("PEDIDO"   ,{|| MOMS662CLIK() }) // VER PEDIDO

                //MESOS         , BROWSE
aAdd(aBrowses,{ oPasta:cCaption , oMsMGet })//GUARDA TODOS OS OBJETOS DE BROUSE DE TODAS AS PASTAS PARA BUSCA NA FUNÇÃO MOMS66Obj ().

Return oMsMGet
/*
===============================================================================================================================
Programa--------: MOMS662CLIK()
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Opcoes do 2 clique nas linhas
Parametros------: NENHUM
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS662CLIK()

Local N := 1
Local C := 1
Private _cRet:="BR_AZUL"

If (oMsMGet:=MOMS66Obj()) = NIL 
   Return _cRet
EndIf

If oMsMGet <> NIL
   N:=oMsMGet:oBrowse:nAt
   C:=oMsMGet:oBrowse:nColPos
   aColsP:=oMsMGet:aCols
   _cRet:=aColsP[N,C]
EndIf

If C = nPosOK .Or. C = nPosOK2//PRIMEIRA COLUNA E SEGUNDA COLUNA

   If !aColsP[N,nPosCar] $ LEGENDAS_ABCP 
      _cRet2:=aColsP[N,nPosOK2]//O QUE VALE PARA A MARECAÇÃO É A COLUNA 2
      If _cRet2 = "LBNO" 
         _cRet2 = "LBOK"//NÃO POSSO MEXER NO _cRet ate validar pq devolvo ele no Retorno abaixo
      Else
         _cRet2 = "LBNO"//NÃO POSSO MEXER NO _cRet ate validar pq devolvo ele no Retorno abaixo
      EndIf
      If MOMS66Val(N,aColsP,_cRet2)
         _cRet:=_cRet2
         aColsP[N,nPosOK ]:=_cRet
         aColsP[N,nPosOK2]:=_cRet
         MOMS66Atu("MARCA",N,aColsP)
         oMsMGet:aCols:=aColsP
         _lEfetivar  := .F.//BLOQUEIA O BOTÃO GERAR
         lClicouMarca:= .T.//Ativa a atualização na troca de pasta
      EndIf
   EndIf

ElseIf C = nPosCar//COLUNA CARGA
   MOMS66LEG(.F.)
ElseIf C = _nPosEst//COLUNA ESTOQUE
   FWMsgRun( ,{|| MOMS66Item("ITENS")},"Lendo Itens..","Aguarde...")
ElseIf C = _nPosCap//COLUNA CAPACIDADE
   MOMS66LEG(.F.)
ElseIf C = _nPosPed//COLUNA PEDIDO//NÃO FUNCIONA
   FWMsgRun( ,{|| MOMS66PPV("S")},"Lendo Pedido..","Aguarde...")
EndIf

Return _cRet//RETORNA O CONTEUDO DELE MESMO 

/*
===============================================================================================================================
Programa--------: M66Valid()
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Valida a ordem digitada
Parametros------: NENHUM
Retorno---------: .T. ou .F.
===============================================================================================================================*/
User Function M66Valid()

Local lRet := .T.
Local cCampo:=ReadVar()

If cCampo = "M->B2_1_QLIBE"
     If oMsMGetG <> NIL
        N:=oMsMGetG:nAt
        _aTabAux:=oMsMGetG:aCols
     Else
        Return .F.   
     EndIf
     If !POSITIVO(M->B2_1_QLIBE)
        Return .F.
     EndIf

     //Carrega fator de conversão se existir
     _nfator := 1
     If SB1->(DBSeek(xFilial("SB1")+LEFT(_aTabAux[N][nPosProde],11)))
        If SB1->B1_CONV == 0
           If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
              _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
           EndIf
        Else
           _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
        EndIf
     EndIf

     M->B2_2_QLIBE:= (M->B2_1_QLIBE * _nfator)//PARA CALCULAR A SEGUNDA UNIDADE DE MEDIDA

     If M->B2_2_QLIBE > _aTabAux[N][nPosDispo]
     
        U_ITMsg("Quantidade digitada em 2M ("+cValToChar(M->B2_2_QLIBE)+") maior que o Saldo disponivel.",'Atenção!',,3) 
        Return .F.
     
     EndIf 

     oMsMGetG:aCols[N][nPos2QLIBE]:= M->B2_2_QLIBE

ElseIf cCampo = "M->B2_2_QLIBE"

     If oMsMGetG <> NIL
        N:=oMsMGetG:nAt
        _aTabAux:=oMsMGetG:aCols
     Else
        Return .F.   
     EndIf

     If !POSITIVO(M->B2_2_QLIBE)
        Return .F.
     EndIf

     If M->B2_2_QLIBE > _aTabAux[N][nPosDispo]
     
        U_ITMsg("Quantidade digitada em 2M ("+cValToChar(M->B2_2_QLIBE)+") maior que o Saldo disponivel.",'Atenção!',,3) 
        Return .F.
     
     EndIf 

     //Carrega fator de conversão se existir
     _nfator := 1
     If SB1->(DBSeek(xFilial("SB1")+LEFT(_aTabAux[N][nPosProde],11)))
        If SB1->B1_CONV == 0
           If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
              _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
           EndIf
        Else
           _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
        EndIf
     EndIf

     M->B2_1_QLIBE:= (M->B2_2_QLIBE / _nfator)//PARA CALCULAR A PRIMEIRA UNIDADE DE MEDIDA

     oMsMGetG:aCols[N][nPosQLIBE]:= M->B2_1_QLIBE

EndIf

Return lRet

/*
===============================================================================================================================
Programa--------: MOMS66Alt()
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Desvincula um pedido de outro pedido vinculado / CORTA ITENS DE PEDIDOS
Parametros------: _lDesvincula
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS66Alt(_lDesvincula)

Local L , P
If !MOMS66Acesso()
   Return .F.
EndIf

If (oMsMGet:=MOMS66Obj()) = NIL 
   Return .F.
EndIf
aColsP:=oMsMGet:aCols
If Len(aColsP) = 0
   Return .F.
EndIf
N:=oMsMGet:oBrowse:nAt	
If ValType(aColsP[N][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return .F.
EndIf

If _lDesvincula// TELA DO BOTÃO "Desvincula Pedidos"

   SC5->(DBSetOrder(1))
   If !Empty(aColsP[N,_nPosPedVin])
      
      If aColsP[n][_nPosRecnos][1] <> 0  .And. U_ITMsg("Confirma DESVINCULAR os Pedidos : "+aColsP[N,_nPosPed]+" - "+aColsP[N,_nPosPedVin]+" ?",'Atenção!',,3,2,2)
          SC5->(DBGoTo( aColsP[n][_nPosRecnos][1] ))

          _cPedAtual:=SC5->C5_FILIAL+SC5->C5_NUM
          If !SC5->(DBSeek( _cPedAtual)) //PEDIDO QUE NÃO EXISTE MAIS NESSA FILIAL
               aColsP[n][nPosCar ]:= "BR_AMARELO"
             aColsP[n][_nPosObs]:= "Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM+". FAÇA O REPROCESSAMENTO."
             U_ITMsg("Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM,'Atenção!',"Faça o reprocessamento ou tente marca novamente esse pedido.",1)
             Return .F.
          EndIf

          If !Empty(SC5->C5_I_PEVIN)
             If (nPos:=aScan(aColsP,{|aPed| aPed[_nPosPed] == SC5->C5_I_PEVIN } ) ) > 0 //PRIMEIRO BUSCA NA MESMA PASTA
                   aColsP[nPos][_nPosPedVin  ]:=" "
                If aColsP[nPos][nPosCar   ] ="BR_CINZA"
                   aColsP[nPos][nPosCar   ]:="DISABLE"
                EndIf
                aColsP[nPos][_nPosRecnos,4]:=.F.
             Else
                 If (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == SC5->C5_I_PEVIN } )) > 0   //Procura o pedido na lista geral de vinculados 
                    _aPedPasta:={}
                    If aPedVin[_nPos,4] == aFoders1[1]                                  //"Cargas Fechadas TOP1"
                       _aPedPasta:=oBrwTOP1:aCols
                    ElseIf aPedVin[_nPos,4] == aFoders1[2]                              //"Cargas Fechadas"
                       _aPedPasta:=oBrwCaFe:aCols
                    ElseIf aPedVin[_nPos,4] == aFoders1[3]                              //PEDIDOS FORA DE PADRÃO
                       _aPedPasta:=oBrwFORA:aCols
                    ElseIf (nPos:=aScan(aBrowses, {|B| B[1] == aPedVin[_nPos,5] } )) > 0//Cargas por Regioes do Brasil - Procura o nome da MESO
                       oMsMGet2:=aBrowses[nPos,2]
                       _aPedPasta:=oMsMGet2:aCols
                       EndIf
                    If !Empty(_aPedPasta) .And. (nPos:=aScan(_aPedPasta,{|aPed| aPed[_nPosPed] == SC5->C5_I_PEVIN } ) ) > 0 //Procura o pedido vinculado na lista de pedidos da aba deles para limpar
                          _aPedPasta[nPos][_nPosPedVin]:=" "
                       If _aPedPasta[nPos][nPosCar ] ="BR_CINZA"
                          _aPedPasta[nPos][nPosCar ]:="DISABLE"
                       EndIf
                       _aPedPasta[nPos][_nPosRecnos,4 ]:=.F.
                       EndIf
                 EndIf
             EndIf
                cPedVinc:=SC5->C5_FILIAL+SC5->C5_I_PEVIN
             If SC5->(DBSeek( cPedVinc )) 
                   SC5->(RecLock("SC5",.F.))
                   SC5->C5_I_PEVIN := " "
                   SC5->(MSUnLock())     
               Else
                U_ITMsg("Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_I_PEVIN,'Atenção!',"O campo de Pedido vinculado desse pedido será limpo.",3) 
               EndIf
            SC5->(DBGoTo( aColsP[n][_nPosRecnos][1] ))
               SC5->(RecLock("SC5",.F.))
               SC5->C5_I_PEVIN        :=" "
               SC5->(MSUnLock())
               aColsP[N,_nPosPedVin  ]:=" "
            If aColsP[N][nPosCar  ] ="BR_CINZA"
               aColsP[N][nPosCar  ]:="DISABLE"
            EndIf

            aColsP[N,_nPosRecnos,4]:=.F.
            U_ITMsg("Pedidos: "+aColsP[N,_nPosPed]+" - "+aColsP[N,_nPosPedVin]+" desvinculados COM SUCESSO.",'Atenção!',,2) 
               _lEfetivar  := .F.//BLOQUEIA O BOTÃO GERAR
            lClicouMarca:= .T.//Ativa a atualização na troca de pasta
          EndIf
       EndIf
   
   Else
      U_ITMsg("Esse pedido "+aColsP[N,_nPosPed]+" não possui pedido vinculado.",'Atenção!',"Posicione em uma linha que o pedido tenha um pedido vinculado para usar essa opção.",3) 
   EndIf
   
   If oMsMGet <> NIL
      oMsMGet:oBrowse:Refresh()
   EndIf

Else// TELA DO BOTAO "CORTAR PRODUTOS"

   If !_lEfetivar//BLOQUEIA O BOTÃO GERAR
      U_ITMsg("Houve Alterações, clique em Reprocessar antes de Cortar os Produtos novamente.",'Atenção!',"",3)  
      Return .F.
   EndIf

// COLUNAS DE SELECAO DE PRODUTOS
   aCab1:={}
   aAdd(aCab1,"")          //01
   aAdd(aCab1,"Codigo")    //02
   aAdd(aCab1,"Descricao") //03
   aAdd(aCab1,"Qtde 2a UM")//04
   aAdd(aCab1,"2a UM")     //05

// COLUNAS DE SELECAO DE PEDIDOS
   aCab2:={}
   aAdd(aCab2,"")          //01
   aAdd(aCab2,"Filial")    //02
   aAdd(aCab2,"Pedido")    //03
   aAdd(aCab2,"Codigo")    //04
   aAdd(aCab2,"Descricao") //05
   aAdd(aCab2,"Qtde 2a UM")//06
   aAdd(aCab2,"2a UM")
   aAdd(aCab2,"Razao Social")
   aAdd(aCab2,"Nome Fantasia")
   aAdd(aCab2,"UF Do Cliente")
   aAdd(aCab2,"Rede")
   aAdd(aCab2,"Nome Rede")
   aAdd(aCab2,"Nome Gerente")
   aAdd(aCab2,"Nome Coord.")
   aAdd(aCab2,"Preço Venda")
   aAdd(aCab2,"Preço Net")
   aAdd(aCab2,"Vlr Total")
   aAdd(aCab2,"Ped. Cliente")
   aAdd(aCab2,"RDC")
   aAdd(aCab2,"Mesorregião")
   aAdd(aCab2,"UF")
   aAdd(aCab2,"Região do Brasil")
   aAdd(aCab2,"Mensagens de Erro")
   _nColMen:=Len(aCab2)
   aAdd(aCab2,"Registro")
   _nColRec:=Len(aCab2)

   cPictQ:=AVSX3('C6_QTDVEN',6)
   For L := 1 TO Len(_aCortaItem)
       If ValType(_aCortaItem[L,4]) = "N"
          _aCortaItem[L,4] := TRANS( (_aCortaItem[L,4]) , cPictQ )
       EndIf
   Next
   
   While .T.

      _cTitulo:='SELECIONE 1 OU MAIS PRODUTOS PARA CORTAR'
                       //      ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      If !U_ITListBox(_cTitulo,aCab1,_aCortaItem, .T.    , 2    ,    ,          ,       ,         ,     ,        , )
         Exit
      EndIf

      _lAtual:=U_ITMsg("Procurar o(s) produto(s) marcado(s) na somente Pasta Atual? ",'Atenção!',,2,2,3,,"ATUAL","TODAS")//OK

      cPictQ:=AVSX3('C6_QTDVEN',6)
      For L := 1 TO Len(_aCortaPed)
          If ValType(_aCortaPed[L,6]) = "N"
             _aCortaPed[L,6] := TRANS( (_aCortaPed[L,6]) , cPictQ )
          EndIf
      Next

      _aCortaSelPed:={}
      _aCortaPed:=aSort( _aCortaPed, , , {|X,Y| X[4] < Y[4] } )//POR ITEM
      For L := 1 TO Len(_aCortaItem)
          If _aCortaItem[L,1]
              For P := 1 TO Len(_aCortaPed)
                  If _aCortaItem[L,2] == _aCortaPed[P,4] .And. (!_lAtual .Or. aScan(aColsP, { |aPed| aPed[_nPosPed] == _aCortaPed[P,3] } ) <> 0 )
                     aAdd(_aCortaSelPed,_aCortaPed[P])
                  EndIf
              Next
          EndIf
      Next
      If Len(_aCortaSelPed) > 0
         _aCortaSelPed:=aSort( _aCortaSelPed, , , {|X,Y| X[2]+X[3] < Y[2]+Y[3] } )//POR FILIAL +PEDIDO
      Else
         U_ITMsg("Nenhum pedido encontrado com esse(s) produto(s) selecionado(s).",'Atenção!',"Selecione outro(s) produto(s).",2) 	      
         Loop
      EndIf

      _cTitulo:='SELECIONE 1 OU MAIS PEDIDOS PARA CORTAR'
                       //      ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons )
      If !U_ITListBox(_cTitulo,aCab2,_aCortaSelPed, .T.    , 2    ,        ,          ,        ,         ,     ,        , )
         Loop
      EndIf   

      _aCortaRes:={}
      For L := 1 TO Len(_aCortaSelPed)
          If _aCortaSelPed[L,1]	     //MARCADOS PARA CORTE
               aAdd(_aCortaRes,_aCortaSelPed[L])
            EndIf
      Next		 

      If Len(_aCortaRes) > 0
         _aCortaRes:=aSort( _aCortaRes, , , {|X,Y| X[2]+X[3] < Y[2]+Y[3] } )//ORDEM DE FILIAL + PEDIDO
      EndIf
      
      If !MOMS66Motivo()
         Loop
      EndIf
      
      _aItensCorta:= {}
      _cSC6Chave:=""
      For L := 1 TO Len(_aCortaRes)
          SC6->(DBGoTo(_aCortaRes[L, _nColRec ] ))
          If SC6->(Deleted())
             Loop
          EndIf
          If !Empty(_cSC6Chave) .And. _cSC6Chave <> SC6->C6_FILIAL+SC6->C6_NUM//QUEBRA POR PEDIDO
             FWMsgRun( ,{|oProc| MOMS047QGR(_cSC6Chave,oProc,_aItensCorta) },"Processando!","Aguarde...") //ALTERA O PEDIDO MSEXECAUTO()
             SC6->(DBGoTo(_aCortaRes[L, _nColRec ] ))
             _aItensCorta:= {}
             _cSC6Chave:=SC6->C6_FILIAL+SC6->C6_NUM
          ElseIf Empty(_cSC6Chave)
             _cSC6Chave:=SC6->C6_FILIAL+SC6->C6_NUM
          EndIf
          // Grava o Array _aItensCorta com todos os itens de um pedidos de vendas para atualização da base de dados
          aAdd(_aItensCorta,{SC6->C6_FILIAL   ,;//01
                             SC6->C6_NUM      ,;//02
                             SC6->C6_ITEM     ,;//03
                             SC6->C6_PRODUTO  ,;//04
                             SC6->C6_LOCAL    ,;//05
                             SC6->C6_QTDVEN   ,;//06
                             "S"              ,;//07
                             SC6->C6_UNSVEN    ;//08
                             })
                      
          lTemItemPraAlterar:=.T.
      Next
      If Len(_aItensCorta) > 0//QUEBRA POR PEDIDO
         FWMsgRun( ,{|oProc| MOMS047QGR(_cSC6Chave,oProc,_aItensCorta) },"Processando!","Aguarde...") //ALTERA O PEDIDO MSEXECAUTO()
      EndIf

       If lTemItemPraAlterar	
         If Len(_aCortaRes) = 0 
            For L := 1 TO Len(_aCortaSelPed)
                If _aCortaSelPed[L,1]	     
                   aAdd(_aCortaRes,_aCortaSelPed[L])
                EndIf
            Next		 
         EndIf
      
         If Len(_aCortaRes) > 0 
            aBotoesM:={}
            aAdd(aBotoesM,{"",{|| U_ITMsgLog(oLbxAux:aArray[oLbxAux:nAt][ _nColMen ], "MENSAGEM" )},"","MENSAGEM"} )
            _bDblClk:={|oLbxAux| U_ITMsgLog(oLbxAux:aArray[oLbxAux:nAt][ _nColMen ], "MENSAGEM" )}
            
            _cTitulo:='RESULTADO DOS CORTES'
                             //          ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
            If !U_ITListBox(_cTitulo,aCab2,_aCortaRes, .T.    , 4    ,        ,          ,        ,         ,     ,        , aBotoesM  ,       ,_bDblClk,           ,          ,         ,       ,          )
               Loop
            EndIf 
        Else
            U_ITMsg("Nenhum PEDIDO SELECIONADO.",'Atenção!',"SELECIONE 1 OU MAIS PEDIDOS",2) 	      
            Loop 	      
        EndIf  

       Else
          U_ITMsg("Nenhum PEDIDO SELECIONADO.",'Atenção!',"SELECIONE 1 OU MAIS PEDIDOS",2) 	      
          Loop
       EndIf
       
       Exit
   
   EndDo

EndIf

Return .T.

/*
===============================================================================================================================
Programa--------: MOMS66B2
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Monta o array com os valores atuais da SB2
Parametros------: _aTelaPedidos,lZera
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS66B2(_aTelaPedidos,lZera)

Local _nX := 0
Local _nY := 0
Local _lSomaPTer:= .F.

SB2->(DBSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL
If lZera
   _aSB2:= {}
EndIf

For _nX := 1 TO Len(_aTelaPedidos)
    
    If _aTelaPedidos[_nX,nPosCar]  $ LEGENDAS_ABCP
       Loop
    EndIf

    _aSC6_do_PV:=_aTelaPedidos[_nX][_nPosRecnos]

    For _nY := 1 TO Len(_aSC6_do_PV[2])
        SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
         If SC6->(Deleted())
            Loop
         EndIf

        If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL)) .AND.;
           (aScan(_aSB2, {|x| x[1] == SB2->B2_FILIAL .And. x[2] == SB2->B2_COD .And. x[7] == SB2->B2_LOCAL})) = 0
        
               _lSomaPTer :=(SC6->C6_FILIAL $ _cFilTer .And. SC6->C6_LOCAL $ _cLocTer)
               
               If MV_PAR09 = 1 .And. SB2->(FIELDPOS("B2_I_QLIBE")) > 0  .And. SB2->B2_I_QLIBE > 0 
                  _nSaldoDisp:=SB2->B2_I_QLIBE
               Else
                  _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)
               EndIf
               
               _nDispInicial:=_nSaldoDisp//DISPONIVEL INICIAL 1UM SEM ZERAR
               
               _nSaldoDisp:=If( _nSaldoDisp < 0 , 0 , _nSaldoDisp )//ZEREI O SALDO NEGATIVO PARA NÃO DAR ERRO NOS CALDULOS DE PESO			   

                aAdd(_aSB2, {SB2->B2_FILIAL ,;              //01 - FILIAL
                             SB2->B2_COD    ,;              //02 - PRODUTO
                             SB2->B2_QATU   ,;              //03 - 1UM
                             SB2->B2_RESERVA,;              //04 - 1UM
                             SB2->B2_QEMP   ,;              //05 - 1UM
                             _nSaldoDisp    ,;              //06 - DISPONIVEL FINAL 1UM SÓ MAIOR OU IGUAL A ZERO
                             SB2->B2_LOCAL  ,;              //07 - ARMAZEM
                             If(_lSomaPTer,SB2->B2_QNPT,0),;//08 - 1UM
                             0              ,;              //09 - Quantidade Carteira na 2ª UM (SOMTORIA BOLINHA VERDE)
                             0              ,;              //10 - Saldo na 2ª UM (DISPONIVEL - BOLINHA VERDE) CALCULADO
                             _nDispInicial  ,;              //11 - DISPONIVEL INICIAL 1UM
                             0              ,;              //12 - SOMATORIA DAS RESERVAS DOS GERENTES 1UM
                             _nSaldoDisp    })              //13 - POSICAO PARA SALVAR O SALDO ANTERIOR A SIMULACAO: INICIA IGUAL PQ NA SIMULACAO PODE TER ITENS NOVOS

                aAdd(_aSB2Inic,  ACLONE( _aSB2[Len(_aSB2)] )  )
        EndIf
    
    Next _nY

Next _nX

Return

/*
===============================================================================================================================
Programa--------: MOMS66PC
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Processa os pedidos para gerar as justificativas
Parametros------: _aTelaPedidos - Array contendo os pedidos a ser processado ,cMarcados,lZera,lSimulacao,oProc
Retorno---------: NENHUM
===============================================================================================================================*/
Static Function MOMS66PC(_aTelaPedidos,cMarcados,lZera,lSimulacao,oProc,cPastaR)

Local _nX,_nY
Local _nPesoPedido  := 0
Local _nPedTotPalete:= 0
Local _aItensPed    := {}
Local _nVlrPGerFin  := 0
Local _nPesoNGerFin := 0
Local cPictP:=AVSX3('C6_VALOR',6)
Default lZera       :=.F.

_nTot :=Len(_aTelaPedidos)
If _nTot = 0 .Or. ValType(_aTelaPedidos[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return _aTelaPedidos
EndIf
_cTot :=AllTrim(Str(_nTot))

Private _nPos:= 0
If lZera //INICIA O CONSUMO
   _nTotPesoLib    := 00 //PESO LIBERADO
   _nTotPalsLib    := 00 //PALETES LIBERADO
   _nTotGerFin     := 00 //ZERA AQUI DE NOVO POR CAUSA DO REPROCESSAMENTO
   _nTotNaoGerFin  := 00 //ZERA AQUI DE NOVO POR CAUSA DO REPROCESSAMENTO
   _nSEstPesoLib   := 00 //PESO LIBERADO SEM OLHA ESTOQUE 
   _nSEstPalsLib   := 00 //PALETES LIBERADO SEM OLHA ESTOQUE 
   _lSomaPontFat   := .T.//SE ZERA LIGA A SOMA DE NOVO PARA REFAZER _nSEstPalsLib
   _aCortaItem     := {} //BOTAO "CORTAR PRODUTOS" 
   _aCortaPed      := {} //BOTAO "CORTAR PRODUTOS" 
   _aPedXProdSE    := {} //BOTAO "PEDIDOS X PRODUTOS SEM ESTOQUE"
   AEVAL(_aTotPonFat,{|x| x[2] := 0})//VALORES GERAL E POR PASTA SEM OLHA ESTOQUE 
ElseIf lSimulacao//REINICIA O CONSUMO 
   _aSB2:=MOMS66aSB2(_aSB2,"VOLTA")  //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
   _nTotPesoLib    := _nBKPPesoLib     //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
   _nTotPalsLib    := _nBKPPalsLib     //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
   _nTotGerFin     := _nBKPGerFin      //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
   _nTotNaoGerFin  := _nBKPNaoGerFin   //RESTAURA AQUI PQ O ESTOQUE DAS REGIOES NÃO CONSOME AINDA PQ É SIMULACAO 
EndIf

//CARREGA OS DADOS DA SB2 PARA O PROCESSAMENTO //***************
If !cMarcados == "D2" //NÃO RECARREGA QUANDO É TROCA DE PASTA
   MOMS66B2(_aTelaPedidos,lZera)
EndIf
//CARREGA OS DADOS DA SB2 PARA O PROCESSAMENTO //***************

For _nX := 1 TO _nTot// Loop NOS PEDIDOS
    _aTelaPedidos[_nX,_nPosRecnos,4]:=.F.//LIMPA A VERIFICACO POR CAUSA DO REPROCESSAMENTO
Next
nConta:=0
SB1->(DBSetOrder(1))
For _nX := 1 TO _nTot//Len(_aTelaPedidos)// Loop NOS PEDIDOS

    If oProc <> NIL
       nConta++
       oProc:cCaption := ("Processando: "+StrZero(nConta,5) +" de "+ _cTot)
       ProcessMessages()
    EndIf

    //LENDO OS MARCADOS 	
    If cMarcados = "M" .And. _aTelaPedidos[_nX,nPosOK2] = "LBNO"//Loop NOS DESMARCADOS
       Loop
    EndIf
    
    //LENDO OS DESMARCADOS 	
    If cMarcados = "D" .And. _aTelaPedidos[_nX,nPosOK2] = "LBOK"//Loop NOS MARCADOS
       Loop
    EndIf

    _aSC6_do_PV:=_aTelaPedidos[_nX][_nPosRecnos]
    SC5->(DBGoTo(_aSC6_do_PV[1]))

    _cPedAtual:=SC5->C5_FILIAL+SC5->C5_NUM
    If !SC5->(DBSeek( _cPedAtual)) //Pedido que não existe mais nessa filial
        _aTelaPedidos[_nX,nPosCar ] := "BR_AMARELO"
        _aTelaPedidos[_nX,_nPosObs] := "Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM+". FAÇA O REPROCESSAMENTO."
        Loop	
    EndIf
    
    // Pedidos para REAGENDAR/futuro/excluidos     OU  Ve se foi verificado já (QUANDO SÃO PEDIDOS VINCULADOS).
    If _aTelaPedidos[_nX][nPosCar] $ LEGENDAS_ABCP .Or. _aTelaPedidos[_nX][_nPosRecnos,4]
       Loop
    EndIf
    
    _nPesoCapacFil :=_aSC6_do_PV[3]//_nCapacPes
    _nPaleCapacFil :=_aSC6_do_PV[5]//_nCapacPal
    _lTemEstoque   :=.T.
    _cProdSEst     :=""
    _nPesoPedido   := 0
    _nPedTotPalete := 0
    _nVlrPGerFin   := 0
    _nPesoNGerFin  := 0
    _aItensPed     := {}
    Default cPastaR:=_aTelaPedidos[_nX,_nPosRGBR]
    _aTelaPedidos[_nX,_nPosObs   ]:=""//LIMPA POR CAUSA DO REPROCESSAMENTO
    _aTelaPedidos[_nX,_nPosPesEst]:=0 //LIMPA POR CAUSA DO REPROCESSAMENTO

    For _nY := 1 TO Len(_aSC6_do_PV[2]) // Loop NO ITENS DO PEDIDO
        
        SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
        If SC6->(Deleted())
           Loop
        EndIf
    
        //REALIZA O CONSUMO DA SB2 
        If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] = SC6->C6_LOCAL })) > 0 				
            
            //            Disponivel      //- RESERVAS DOS GERENTES + RESERVA DO GERENTE DO PEDIDOS POSICINADO
            _nSaldoDisp:=_aSB2[_nPos][06] //- _aSB2[_nPos][12]    //+ _nReservGer

            _aSB2[_nPos][09] += SC6->C6_UNSVEN //Quantidade Carteira na 2ª UM - BOTÃO ITENS DO PEDIDO // SOMTORIA TODAS AS BOLINHAS

            If _nSaldoDisp  >= SC6->C6_QTDVEN //.AND. (_nReservGer = 0 .Or. _nReservGer > SC6->C6_QTDVEN) // <<<<<<<<<<<<< CONSOME O ESOQUE  <<<<<<<<<<<<<<
               
               _aSB2[_nPos][06]-= SC6->C6_QTDVEN // SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP // DISPONIVEL
                              
               _aSC6_do_PV[2][_nY,2]:=.F. //Marca o item que não tem estoque
               aAdd(_aItensPed,{SC6->( Recno() ),SC6->C6_QTDVEN,SC5->( Recno() ) , SC6->C6_UNSVEN })

                //BOTÃO: "VER / CORTAR Itens Pedido""
                _nQtdeATend := SC6->C6_QTDVEN
                _nQtdeFalta := 0
                _nPesoFalta := 0
            
            Else//NÃO TEM MAIS ESTOQUE 
                
                _aSC6_do_PV[2][_nY,2]:=.F. //Marca o item que não tem estoque
                _lTemEstoque:=.F.
                _cProdSEst+="[ "+AllTrim(SC6->C6_PRODUTO)+"/ Qtde "+AllTrim(TRANS(SC6->C6_QTDVEN,"@E 999,999,999,999.999")) +" > Saldo "+AllTrim(TRANS(_nSaldoDisp,"@E 999,999,999,999.999")) +" ]"
                
                //BOTÃO: "VER / CORTAR Itens Pedido""
                _nQtdeATend := _nSaldoDisp
                _nQtdeFalta := (SC6->C6_QTDVEN - _nSaldoDisp)
                _nPesoFalta := (SC6->C6_I_PTBRU / SC6->C6_QTDVEN)  * (SC6->C6_QTDVEN - _nSaldoDisp)

            EndIf
            //Carrega fator de conversão se existir
            _nfator := 1
            If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
               If SB1->B1_CONV == 0
                  If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                     _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                  EndIf
               Else
                  _nfator := IIf(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
               EndIf
            EndIf
            _aTelaPedidos[_nX,_nPosPesEst]+= _nPesoFalta

            //BOTÃO: "VER / CORTAR Itens Pedido""
            _aSC6_do_PV[2][_nY,3]:=(_nQtdeATend*_nfator)
            _aSC6_do_PV[2][_nY,4]:=(_nQtdeFalta*_nfator)//QTDE FALTANTE
            _aSC6_do_PV[2][_nY,5]:=_nPesoFalta

        EndIf
         
    Next _nY

    _aTelaPedidos[_nX][_nPosRecnos]:=ACLONE(_aSC6_do_PV)
    
    _lPalitizada  :=_aTelaPedidos[_nX][_nPosTPCA] = "1" //C5_I_TIPCA
    _nPedTotPalete:=_aTelaPedidos[_nX][_nPosPalete]//Qtde de Paletes do Pedido 	
    _nPesoPedido  :=SC5->C5_I_PESBR

    SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
    
    If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = 'S' 
       _nVlrPGerFin+=_aTelaPedidos[_nX][_nPosTotPed]
    Else
       _nPesoNGerFin+=SC5->C5_I_PESBR
    EndIf

    If !Empty(_cProdSEst)
       _aTelaPedidos[_nX,_nPosObs]:="Prods. s/ Estoque: "+_cProdSEst
    EndIf

    //VINCULADOS
    //VER SE TEM PEDIDO VINVCULADO TESTA AQUI JUNTO COM O OUTRO PEDIDO
    nPosVinc:=0
    If (nPosVinc:=aScan(_aTelaPedidos,{|aPed| aPed[_nPosPed] == SC5->C5_I_PEVIN } ) ) > 0 ;//Procura o pedido vinculado NA _aTelaPedidos
                 .And. !_aTelaPedidos[nPosVinc][_nPosRecnos,4]                            ;// Ve se não foi verificado ainda
                 .And. !_aTelaPedidos[nPosVinc,nPosCar] $ LEGENDAS_ABCP                    ;// Ve se não é para agendar / Ve se não tá excluido / Depois de hoje
                 
       
       _aTelaPedidos[nPosVinc,_nPosRecnos,4]:=.T.//MARCA QUE EU JÁ VERIFIQUEI ESSE PEDIDO PARA CONTROLE DO VINCULADO
       _aTelaPedidos[nPosVinc][_nPosObs]    :="" //LIMPA POR CAUSA DO REPROCESSMENTO
       _aTelaPedidos[nPosVinc,_nPosPesEst]  := 0 //LIMPA POR CAUSA DO REPROCESSMENTO

       _cProdSEst:=""
       _aSC6_do_PV:=_aTelaPedidos[nPosVinc][_nPosRecnos]
       SC5->(DBGoTo(_aSC6_do_PV[1]))//PEDIDO VINCULADO
       
       For _nY := 1 TO Len(_aSC6_do_PV[2]) // Loop NO ITENS DO PEDIDO VINCULADO
            
            SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
            If SC6->(Deleted())
               Loop
            EndIf
            //REALIZA O CONSUMO DA SB2 

            If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] = SC6->C6_LOCAL })) > 0 				

                //            Disponivel      //- reservas dos gerentes + reserva do gerente do pedidos posicinado
                _nSaldoDisp:=_aSB2[_nPos][06] //- _aSB2[_nPos][12]    //+ _nReservGer

               _aSB2[_nPos][09] += SC6->C6_UNSVEN //Quantidade Carteira na 2ª UM - itens do pedido // SOMTORIA TODAS AS BOLINHAS

               If _nSaldoDisp  >= SC6->C6_QTDVEN //.AND. (_nReservGer = 0 .Or. _nReservGer > SC6->C6_QTDVEN) // <<<<<<<<<<<<<<<<<<<<<<<<<<<
                  
                  _aSB2[_nPos][06]       -= SC6->C6_QTDVEN // SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP // DISPONIVEL

                   aAdd(_aItensPed,{SC6->( Recno() ),SC6->C6_QTDVEN,SC5->( Recno() ) , SC6->C6_UNSVEN })
                   _aSC6_do_PV[2][_nY,2]:=.T. //Marca o item que TEM ESTOQUE PARA Gravar ZY8 (MOMS66ZY8 ())

                   //BOTÃO: "VER / CORTAR Itens Pedido""
                   _nQtdeATend := SC6->C6_QTDVEN
                   _nQtdeFalta := 0
                   _nPesoFalta := 0

                Else
                    
                    _aSC6_do_PV[2][_nY,2]:=.F. //Marca o item que NAO TEM ESTOQUE PARA Gravar ZY8 (MOMS66ZY8 ())
                    _lTemEstoque:=.F.
                    _cProdSEst+="[ "+AllTrim(SC6->C6_PRODUTO)+"/ Qtde "+AllTrim(TRANS(SC6->C6_QTDVEN,"@E 999,999,999,999.999")) +" > Saldo "+AllTrim(TRANS(_nSaldoDisp,"@E 999,999,999,999.999")) +" (V) ]"
                    
                    //BOTÃO: "VER / CORTAR Itens Pedido""
                    _nQtdeATend := (_nSaldoDisp*_nfator)
                    _nQtdeFalta := ((SC6->C6_QTDVEN - _nSaldoDisp)*_nfator)
                    _nPesoFalta := (SC6->C6_I_PTBRU / SC6->C6_QTDVEN)  * (SC6->C6_QTDVEN - _nSaldoDisp)
               
                EndIf
                
                //Carrega fator de conversão se existir
                _nfator := 1
                If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
                   If SB1->B1_CONV == 0
                      If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                         _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                      EndIf
                   Else
                      _nfator := IIf(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
                   EndIf
                EndIf
                _aTelaPedidos[nPosVinc,_nPosPesEst]+= _nPesoFalta
            
                //BOTÃO: "VER / CORTAR Itens Pedido""
                _aSC6_do_PV[2][_nY,3]:=(_nQtdeATend*_nfator)
                _aSC6_do_PV[2][_nY,4]:=(_nQtdeFalta*_nfator)//QTDE FALTANTE
                _aSC6_do_PV[2][_nY,5]:=_nPesoFalta

            EndIf
             
        Next _nY
        
           _nPedTotPalete+=_aTelaPedidos[nPosVinc][_nPosPalete]
           _nPesoPedido+=SC5->C5_I_PESBR

        SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))

        If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = 'S' 
           _nVlrPGerFin+=_aTelaPedidos[nPosVinc][_nPosTotPed]
        Else   
           _nPesoNGerFin+=SC5->C5_I_PESBR
        EndIf
        
        If !Empty(_cProdSEst)
           _aTelaPedidos[nPosVinc,_nPosObs]:="Prods. s/ Estoque: "+_cProdSEst
        EndIf
        _aTelaPedidos[nPosVinc][_nPosRecnos]:=ACLONE(_aSC6_do_PV)

    EndIf
// VINCULADOS

//ESTOQUE
    If _lTemEstoque 
       _aTelaPedidos[_nX,_nPosEst]:="ENABLE"//COLUNA ESTOQUE SIMULACAO 
       If nPosVinc <> 0//Pedido Vinculdo se tiver
          _aTelaPedidos[nPosVinc,_nPosEst]:="ENABLE"//COLUNA ESTOQUE
       EndIf
    Else
       _aTelaPedidos[_nX,_nPosEst]:="DISABLE"//COLUNA ESTOQUE SIMULACAO 
       If nPosVinc <> 0//Pedido Vinculdo se tiver
          _aTelaPedidos[nPosVinc,_nPosEst]:="DISABLE"//COLUNA ESTOQUE
       EndIf
    EndIf
//ESTOQUE

//CAPACIDADE
    If _lPalitizada//COM PALETE

       If _lSomaPontFat
          _nSEstPalsLib+=_nPedTotPalete     // VALOR TOTAL LIBERADO SEM OLHA ESTOQUE 
          If _nSEstPalsLib <= _nPaleCapacFil// LIIMITE DA CAPACIDADE DE PALETES DA FILIAL
               _aTotPonFat[1,2] += _nVlrPGerFin  // VALOR TOTAL LIBERADO SEM OLHA ESTOQUE 
             If (nPos:=aScan(_aTotPonFat,{|P| P[1] == cPastaR})) > 0 
                 _aTotPonFat[nPos,2]+=_nVlrPGerFin
             EndIf
          EndIf
       EndIf

       _nTotPalsLib +=_nPedTotPalete

       If _nTotPalsLib <= _nPaleCapacFil//LIIMITE DA CAPACIDADE DE PALETES DA FILIAL
          _lTemCapacidade:=.T.
          _aTelaPedidos[_nX,_nPosCap]:="ENABLE"//COLUNA CAPACIDADE
          If nPosVinc <> 0//Pedido Vinculdo se tiver
                _aTelaPedidos[_nX     ,_nPosObs]:="Pedido ("+_aTelaPedidos[_nX     ,_nPosPed]+"+"+_aTelaPedidos[_nX     ,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) < "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[_nX     ,_nPosObs])," / "+_aTelaPedidos[_nX     ,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosObs]:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) < "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[nPosVinc,_nPosObs])," / "+_aTelaPedidos[nPosVinc,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosCap]:="ENABLE"//COLUNA ESTOQUE
          Else
               _aTelaPedidos[_nX,_nPosObs]:="Pedido DENTRO da capacidade: "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) < "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[_nX,_nPosObs])," / "+_aTelaPedidos[_nX,_nPosObs],"")
          EndIf   
       Else
          _lTemCapacidade:=.F.
          _aTelaPedidos[_nX,_nPosCap]:="DISABLE"//COLUNA SEM CAPACIDADE
          If nPosVinc <> 0//Pedido Vinculdo se tiver
             _aTelaPedidos[_nX     ,_nPosObs]:="Pedido ("+_aTelaPedidos[_nX     ,_nPosPed]+"+"+_aTelaPedidos[_nX     ,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) > "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[_nX     ,_nPosObs])," / "+_aTelaPedidos[_nX     ,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosObs]:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) > "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[nPosVinc,_nPosObs])," / "+_aTelaPedidos[nPosVinc,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosCap]:="DISABLE"//COLUNA ESTOQUE
          Else
             _aTelaPedidos[_nX,_nPosObs]:="Pedido FORA da capacidade: ( "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999.999"))+" ) > "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999.999")+" Paletes ")+If(!Empty(_aTelaPedidos[_nX,_nPosObs])," / "+_aTelaPedidos[_nX,_nPosObs],"")
          EndIf
       EndIf

    Else//SEM PALETE / POR PESO

       If _lSomaPontFat
          _nSEstPesoLib+=_nPesoPedido       // VALOR TOTAL LIBERADO SEM OLHA ESTOQUE 
          If _nSEstPesoLib <= _nPesoCapacFil// LIIMITE DA CAPACIDADE DE PALETES DA FILIAL
               _aTotPonFat[1,2] += _nVlrPGerFin  // VALOR TOTAL LIBERADO SEM OLHA ESTOQUE 
             If (nPos:=aScan(_aTotPonFat,{|P| P[1] == cPastaR })) > 0 
                 _aTotPonFat[nPos,2]+=_nVlrPGerFin
             EndIf
          EndIf
       EndIf

       _nTotPesoLib +=_nPesoPedido

       If _nTotPesoLib <= _nPesoCapacFil//LIIMITE DA CAPACIDADE DE PESO DA FILIAL
          _lTemCapacidade:=.T.
          _aTelaPedidos[_nX,_nPosCap]:="ENABLE"//COLUNA CAPACIDADE
          If nPosVinc <> 0//Pedido Vinculdo se tiver
                _aTelaPedidos[_nX,_nPosObs]     :="Pedido ("+_aTelaPedidos[_nX     ,_nPosPed]+"+"+_aTelaPedidos[_nX     ,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) < KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[_nX     ,_nPosObs])," / "+_aTelaPedidos[_nX     ,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosObs]:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) < KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[nPosVinc,_nPosObs])," / "+_aTelaPedidos[nPosVinc,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosCap]:="ENABLE"//COLUNA CAPACIDADE
          Else
                 _aTelaPedidos[_nX,_nPosObs]:="Pedido DENTRO da capacidade: "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) < KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[_nX,_nPosObs])," / "+_aTelaPedidos[_nX,_nPosObs],"")
          EndIf
       Else
          _lTemCapacidade:=.F.
          _aTelaPedidos[_nX,_nPosCap]:="DISABLE"//COLUNA SEM CAPACIDADE
          If nPosVinc <> 0//Pedido Vinculdo se tiver
             _aTelaPedidos[_nX     ,_nPosObs]:="Pedido ("+_aTelaPedidos[_nX     ,_nPosPed]+"+"+_aTelaPedidos[_nX     ,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) > KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[_nX     ,_nPosObs])," / "+_aTelaPedidos[_nX     ,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosObs]:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) > KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[nPosVinc,_nPosObs])," / "+_aTelaPedidos[nPosVinc,_nPosObs],"")
             _aTelaPedidos[nPosVinc,_nPosCap]:="DISABLE"//COLUNA CAPACIDADE
          Else
             _aTelaPedidos[_nX,_nPosObs]:="Pedido FORA da capacidade: ( "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999.999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999.999"))+" ) > KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999.999"))+If(!Empty(_aTelaPedidos[_nX,_nPosObs])," / "+_aTelaPedidos[_nX,_nPosObs],"")
          EndIf
       EndIf

    EndIf
// CAPACIDADE

    If !_lTemEstoque .Or. !_lTemCapacidade

        //ESTORNA RESERVA VIRTUAL DO PEDIDO TODO DO VINCULADO TB
        For _nY := 1 TO Len(_aItensPed)
            
            SC5->(DBGoTo( _aItensPed[_nY,3] ))
            SC6->(DBGoTo( _aItensPed[_nY,1] ))
            
            If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] = SC6->C6_LOCAL })) > 0 				
                
                _aSB2[_nPos][06] += _aItensPed[_nY,2]//1um
                
            EndIf
        Next

        If _lPalitizada
           _nTotPalsLib -=_nPedTotPalete
        Else
           _nTotPesoLib -=_nPesoPedido
        EndIf		    
        
        _aTelaPedidos[_nX][nPosCar]:="DISABLE"//COLUNA CARREGAMENTO
        If nPosVinc <> 0//Pedido Vinculdo se tiver
           _aTelaPedidos[nPosVinc][nPosCar]:="DISABLE"//COLUNA CARREGAMENTO
        EndIf
    Else
        _aTelaPedidos[_nX][nPosCar]:="ENABLE"//COLUNA CARREGAMENTO
        If nPosVinc <> 0//Pedido Vinculdo se tiver
           _aTelaPedidos[nPosVinc][nPosCar]:="ENABLE"//COLUNA CARREGAMENTO
        EndIf
    EndIf

    If _aTelaPedidos[_nX][nPosCar] = "ENABLE" //COLUNA CARREGAMENTO       
       _aTelaPedidos[_nX][nPosOK] := "LBOK"   //SIMULACAO DO USO SO ESTOQUE (_aSB2)
       If !lSimulacao
          _aTelaPedidos[_nX][nPosOK2] :="LBOK"//USO DO ESTOQUE (_aSB2) REAL 
       EndIf
       If nPosVinc <> 0//Pedido Vinculdo se tiver
          _aTelaPedidos[nPosVinc][nPosOK] :="LBOK"   //SIMULACAO 
          If !lSimulacao
             _aTelaPedidos[nPosVinc][nPosOK2]:="LBOK"//REAL 
          EndIf
       EndIf
       _nTotGerFin   +=_nVlrPGerFin //VALOR
       _nTotNaoGerFin+=_nPesoNGerFin//PESO	
    Else
       _aTelaPedidos[_nX][nPosOK ] :="LBNO"        // SIMULACAO DO USO SO ESTOQUE (_aSB2)
       _aTelaPedidos[_nX][nPosOK2] :="LBNO"        // USO DO ESTOQUE (_aSB2) REAL 
       If nPosVinc <> 0                            // Pedido Vinculdo se tiver
          _aTelaPedidos[nPosVinc][nPosOK ]:="LBNO" // SIMULACAO 
          _aTelaPedidos[nPosVinc][nPosOK2]:="LBNO" // REAL 
       EndIf
    EndIf

    If _aTelaPedidos[_nX,_nPosEst] = "DISABLE"//COLUNA ESTOQUE *** VAI PARA O BOTÃO DE CORTES DE PRODUTO ****
    
        _aSC6_do_PV:=_aTelaPedidos[_nX][_nPosRecnos]
        SC5->(DBGoTo(_aSC6_do_PV[1]))

        For _nY := 1 TO Len(_aSC6_do_PV[2]) // For NOS ITENS DOS PEDIDOS VERMELHO (_aTelaPedidos[_nX,_nPosEst] = "DISABLE")
            
            SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
            If SC6->(Deleted())
               Loop
            EndIf

            If (_nPos:=aScan(_aCortaItem, {|x| x[2] == SC6->C6_PRODUTO  })) = 0
                _aItens:={}	    	
                aAdd(_aItens,.F.)
                aAdd(_aItens,SC6->C6_PRODUTO)
                aAdd(_aItens,SC6->C6_DESCRI )
                aAdd(_aItens,SC6->C6_UNSVEN )//C6_UNSVEN - A SOMATOTIA É DENTRO DO If ABAIXO **
                aAdd(_aItens,SC6->C6_SEGUM  )//C6_SEGUM
                
                aAdd(_aCortaItem,_aItens)//TELA DE SELECAO DE PRODUTOS
            EndIf

            If (_nPos:=aScan(_aCortaPed, {|x| x[2] == SC6->C6_FILIAL .And. x[3] == SC6->C6_NUM .And. x[4] == SC6->C6_PRODUTO })) = 0 				
                _aItens:={}
                aAdd(_aItens,.F.)            //01      
                aAdd(_aItens,SC6->C6_FILIAL )//02                  
                aAdd(_aItens,SC6->C6_NUM    )//03                  
                aAdd(_aItens,SC6->C6_PRODUTO)//04
                aAdd(_aItens,SC6->C6_DESCRI )//05
                aAdd(_aItens,SC6->C6_UNSVEN )//C6_UNSVEN
                aAdd(_aItens,SC6->C6_SEGUM  )//C6_SEGUM
                aAdd(_aItens,SC5->C5_I_NOME )
                aAdd(_aItens,SC5->C5_I_FANTA)
                aAdd(_aItens,SC5->C5_I_EST  )
                aAdd(_aItens,SC5->C5_I_GRPVE)
                aAdd(_aItens,Posicione("ACY",1,xFilial("ACY")+SC5->C5_I_GRPVE,"ACY_DESCRI"))
                aAdd(_aItens,SC5->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND3,"A3_NOME"))
                aAdd(_aItens,SC5->C5_VEND2+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NOME"))
                aAdd(_aItens,TRANS(SC6->C6_PRCVEN , cPictP ))
                aAdd(_aItens,TRANS(SC6->C6_I_PRNET, cPictP ))
                aAdd(_aItens,TRANS(SC6->C6_VALOR  , cPictP ))
                aAdd(_aItens,SC6->C6_PEDCLI)
                aAdd(_aItens,SC5->C5_I_ENVRD)
                aAdd(_aItens,_aTelaPedidos[_nX][_nPosMeso])
                aAdd(_aItens,_aTelaPedidos[_nX][_nPosUF])
                aAdd(_aItens,_aTelaPedidos[_nX][_nPosRGBR])
                aAdd(_aItens,"" )    
                aAdd(_aItens,SC6->(RECNO()) )
                
                aAdd(_aCortaPed,_aItens)//TELA DE SELECAO DE PEDIDOS

                If (_nPos:=aScan(_aCortaItem, {|x| x[2] == SC6->C6_PRODUTO  })) > 0 				
                   _aCortaItem[_nPos][4]  += SC6->C6_UNSVEN // SOMA AQUI PARA NÃO DUPLICAR A QUANTIDADE DO PRODUTO **
                EndIf

            EndIf

            If (_nPos:=aScan(_aPedXProdSE, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_NUM .And. x[8] == SC6->C6_PRODUTO })) = 0 				
               _cSemEstoque:="SIM"
               If _aSC6_do_PV[2][_nY,4] = 0// QTDE FALTANTE
                  //_cSemEstoque:="NAO"
                  Loop // NÃO POE O ITEM NA LISTA 
               EndIf
               _aItens:={}
               aAdd(_aItens,SC6->C6_FILIAL)         //01
               aAdd(_aItens,SC6->C6_NUM   )         //02
               aAdd(_aItens,SC5->C5_I_NOME)//Cliente//03
               aAdd(_aItens,Posicione("SA1",1,xFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI ,"A1_GRPVEN"))//Rede  //04
               aAdd(_aItens,SC5->C5_VEND3+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND3,"A3_NOME"))//Gerente      //05
               aAdd(_aItens,SC5->C5_VEND2+"-"+Posicione("SA3",1,xFilial("SA3")+SC5->C5_VEND2,"A3_NOME"))//Coordenador  //06
               aAdd(_aItens,SC5->C5_I_EST  )        //07
               aAdd(_aItens,SC6->C6_PRODUTO)        //08
               aAdd(_aItens,SC6->C6_DESCRI )        //09
               aAdd(_aItens,SC6->C6_LOCAL  )//Local //10
               aAdd(_aItens,SC6->C6_UNSVEN )//Quantidade Carteira na 2ª UM //11
               aAdd(_aItens,SC6->C6_SEGUM  )//2ª UM //12
               aAdd(_aItens,"")//Qtde Carteira 2a UM//13
               aAdd(_aItens,"")//Qtde Disponivel 2a UM  Inicial //14
               aAdd(_aItens,_cSemEstoque)//Sem Estoque ? //15
               
               aAdd(_aPedXProdSE,_aItens)//TELA DO BOTAO "PEDIDOS X PRODUTOS SEM ESTOQUE"
            EndIf
           
        Next _nY
    EndIf
    
Next _nX
// VINCULADOS

Return _aTelaPedidos

/*
===============================================================================================================================
Programa--------: MOMS66SEC
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Retorna sequencia da ZY3 
Parametros------: NENHUM
Retorno---------: _cSec: proxima sequencia
===============================================================================================================================*/
Static Function MOMS66SEC()

Local _cSec := "0001" 
ZY3->(DBSetOrder(1)) // ZY3_FILIAL+ZY3_NUMPV+ZY3_SEQUEN 
If ZY3->(DBSeek( xFilial("ZY3")+SC5->C5_NUM ))
    While ZY3->(!Eof()) .And. ZY3->ZY3_NUMPV == SC5->C5_NUM .And. ZY3->ZY3_FILIAL = xFilial("ZY3")
        If ZY3->ZY3_SEQUEN >= _cSec
            _cSec := StrZero(Val(ZY3->ZY3_SEQUEN)+1,4)
        EndIf
        ZY3->(DBSkip())
    EndDo
EndIf
Return _cSec

/*
===============================================================================================================================
Função------------: MOMS66KG
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------:  Retorna peso bruto da quantidade informada.
Parametros--------: _cProd,_nQtde,_nPesoBruto
Retorno-----------: _nPeso
===============================================================================================================================
*/
Static Function MOMS66KG(_cProd,_nQtde,_nPesoBruto)

Local _nPeso := 0
If SB1->(DBSeek(xFilial("SB1")+_cProd))
   If SB1->B1_I_PCCX > 0 .And. _nPesoBruto <> 0 // Peso Variável
      _nPeso := _nPesoBruto
   Else
      _nPeso := _nQtde * SB1->B1_PESBRU
   EndIf
EndIf

Return _nPeso

/*===============================================================================================================================
Programa----------: MOMS66Proc
Autor-------------: Alex Wallauer
Data da Criacao---: 03/05/2024
Descrição---------: LIERACAO DOS PEDIDOS
Parametros--------: oProc
Retorno-----------: NENHUM
===============================================================================================================================*/
Static Function MOMS66Proc(oProc)

Local P , B

_lGravaLOG  :=.T.//COLOCAR PARAMENTRO (ZP1) AQUI CASO NÃO PRECISE GRAVAR O LOG 
_aColsTGrv  :={} //GRAVA NA FUNCAO MOMS66Grv () PARA MOSTRA NA TELA DEPOIS NA FUNCAO MOMS66TGrv ()
nLiberados  := 0 //GRAVA NA FUNCAO MOMS66Grv () PARA MOSTRA NA TELA DEPOIS NA FUNCAO MOMS66TGrv ()
_nTotPesoLib:= 0 //GRAVA NA FUNCAO MOMS66Grv () PARA MOSTRA NA TELA DEPOIS NA FUNCAO MOMS66TGrv ()
_nTotPalsLib:= 0 //GRAVA NA FUNCAO MOMS66Grv () PARA MOSTRA NA TELA DEPOIS NA FUNCAO MOMS66TGrv ()

Private _cTime:=TIME()//UM HORARIO SÓ PARA TODOS 
Private _cVinc:=DToS(_dHoje)+SubStr(_cTime,1,5)
oProc:cCaption:="Liberando Pedidos Cargas TOP1..."
ProcessMessages()
_cPasta:="1-"+aFoders1[1]+" "
_aPedTOP1:=oBrwTOP1:aCols
BEGIN TRANSACTION
MOMS66Grv(_aPedTOP1,oProc,.F.,_cPasta)
END TRANSACTION

oProc:cCaption:="Liberando Pedidos Cargas Fechadas..."
ProcessMessages()
_cPasta:="2-"+aFoders1[2]+" "
_aPedCAFE:=oBrwCaFe:aCols
BEGIN TRANSACTION
MOMS66Grv(_aPedCAFE,oProc,.F.,_cPasta)
END TRANSACTION

oProc:cCaption:="Liberando Pedidos Fora de Padrão..."
ProcessMessages()
_cPasta:="3-"+aFoders1[3]+" "
_aPedFORA:=oBrwFORA:aCols
BEGIN TRANSACTION
MOMS66Grv(_aPedFORA,oProc,.F.,_cPasta)
END TRANSACTION

_cPasta:="4-"
For P := 1 TO Len(aPedsReg1) 
     If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg1[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       oProc:cCaption:="Liberando Pedidos "+aFoldReg1[P]
       ProcessMessages()
       MOMS66PreGrv(_aPedPasta,oProc,_cPasta)
     EndIf
Next
For P := 1 TO Len(aPedsReg2) 
     If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg2[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       oProc:cCaption:="Liberando Pedidos "+aFoldReg2[P]
       ProcessMessages()
       MOMS66PreGrv(_aPedPasta,oProc,_cPasta)
     EndIf
Next
For P := 1 TO Len(aPedsReg3) 
     If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg3[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       oProc:cCaption:="Liberando Pedidos "+aFoldReg3[P]
       ProcessMessages()
       MOMS66PreGrv(_aPedPasta,oProc,_cPasta)
     EndIf
Next
For P := 1 TO Len(aPedsReg4) 
     If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg4[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       oProc:cCaption:="Liberando Pedidos "+aFoldReg4[P]
       ProcessMessages()
       MOMS66PreGrv(_aPedPasta,oProc,_cPasta)
     EndIf
Next
For P := 1 TO Len(aPedsReg5) 
     If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg5[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       oProc:cCaption:="Liberando Pedidos "+aFoldReg5[P]
       ProcessMessages()
       MOMS66PreGrv(_aPedPasta,oProc,_cPasta)
    EndIf
Next

Return  MOMS66TGrv(_aColsTGrv,oProc)//TELA DE LOG DE TODAS AS GRAVAÇÕES DE TODAS AS PASTAS

/*===============================================================================================================================
Programa----------: MOMS66Grv
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: LIERACAO DOS PEDIDOS
Parametros--------: _aTelaPedidos,oProc,lTemColCarga,_cPasta
Retorno-----------: NENHUM
===============================================================================================================================*/
Static Function MOMS66Grv(_aTelaPedidos,oProc,lTemColCarga,_cPasta,_cC5Agrupamento)

Local _nX , P
Local nConta:=0
Local _nTot :=Len(_aTelaPedidos)
Local _cTot :=AllTrim(Str(_nTot))
Default lTemColCarga := .T.//PASTAS COM A COLUNA DA CARGA VALIDADA NAS MESORREGIÕES
Default _cC5Agrupamento:=""

If _nTot = 0 .Or. ValType(_aTelaPedidos[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return .F.
EndIf
_lDisarmou:=.F.
SC5->(DBSetOrder(1))
For _nX := 1 TO _nTot// Loop NOS PEDIDOS
        
    If oProc <> NIL
       nConta++
       oProc:cCaption := ("Processando: "+StrZero(nConta,5) +" de "+ _cTot+" - Liberados: "+CValToChar(nLiberados))
       ProcessMessages()
    EndIf

    If _aTelaPedidos[_nX,nPosCar] = "BR_BRANCO" 
       Loop
    EndIf

    _aSC6_Produtos:=_aTelaPedidos[_nX][_nPosRecnos][2]
    SC5->(DBGoTo(_aTelaPedidos[_nX][_nPosRecnos][1]))
    
    _cPedAtual:=SC5->C5_FILIAL+SC5->C5_NUM

    If !SC5->(DBSeek( _cPedAtual)) 
        _aTelaPedidos[_nX,nPosCar ]:= "BR_AMARELO"//REJEITADO
        _aTelaPedidos[_nX,_nPosObs]:= "Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM
        Loop
    EndIf

    If Empty(_aTelaPedidos[_nX,_nPosObs])
       _aTelaPedidos[_nX,_nPosObs]:= "Pedido não PROCESSADO"
    EndIf

    If _aTelaPedidos[_nX,nPosCar] = "BR_PRETO/BR_CINZA" .And. SC5->C5_I_AGEND $ "M,A" .And. SC5->C5_TPFRETE <> "F"  .And. SC5->C5_I_OPER <> "20" .And. _aTelaPedidos[_nX,_nPosNes] < _dHoje

       If _lSimular
          _aTelaPedidos[_nX,_nPosObs] := "Pedido seria alterado para Reagendamento. Qtd reagend. Atual: "+CValToChar(SC5->C5_I_QTDA)
          Loop
       EndIf
   
       BEGIN TRANSACTION
          //Alterar o tipo para R- Reagendar ou  N- Reagendar com Multa // Somar mais um no Contador do Reagendamento da SC5 
          //(Campo novo: C5_I_QTDA – Quantidade de Reagendamento) // E não mostrar na lista de pedidos pendentes mandar para Logística  
          SC5->(RecLock("SC5",.F.))
          If SC5->C5_I_AGEND = "M"//Agendado com Multa
             SC5->C5_I_AGEND:= "N"//Reagendar com Multa
                //SC5->C5_I_QTDA := SC5-> C5_I_QTDA+1
          ElseIf SC5->C5_I_AGEND = "A"//Agendado
             SC5->C5_I_AGEND:= "R"    //Reagendar
                //SC5->C5_I_QTDA := SC5-> C5_I_QTDA+1
          EndIf
          SC5->(MSUnLock())
          _aTelaPedidos[_nX,_nPosObs] := "Pedido FOI alterado para Reagendamento. Qtd reagend.: "+CValToChar(SC5->C5_I_QTDA)
   
          MOMS66ZY3("006", _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) //REAGENDAR
       END TRANSACTION
       
       Loop// Loop DOS PRETOS

    EndIf

    Begin Sequence

       //PASTAS 1,2,3 OU PASTAS DAS MESORREGIÕES COM CARGA VALIDADA
       If _aTelaPedidos[_nX,nPosCar]        == "ENABLE" .AND.;//CARREGAR SIM 
          _aTelaPedidos[_nX][nPosOK2]       == "LBOK"   .AND.;//MARCADO REAL
          (!lTemColCarga       .Or. !Empty(_aTelaPedidos[_nX][nPosC1]) )
          //MARCADO PASTAS 1,2,3  OU  MARCADO COM CARGA VALIDADA NAS MESOS

          If _lSimular
             _aTelaPedidos[_nX,_nPosObs] := "1-Pedido Talvez seria LIBERADO"
             If _aTelaPedidos[_nX][_nPosTPCA] = "1"//PALITIZADO
                _nTotPalsLib+=_aTelaPedidos[_nX][_nPosPalete]
             Else
                _nTotPesoLib+=SC5->C5_I_PESBR
             EndIf
             BREAK
          EndIf

          If lTemColCarga .And. _lDisarmou
             _aTelaPedidos[_nX,_nPosObs] := "2-Pedido não liberado pq a carga dele teve um pedido que não foi liberar."
             BREAK
          EndIf

          _cLogErro:=""//Preenchido na funcao Ver_Lib_PV ()
          If Ver_Lib_PV(SC5->C5_FILIAL+SC5->C5_NUM)//LIBERA O PEDIDO SEM ALTERACOES 
             _SeqZY3 := MOMS66ZY3("025", _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) //ESTOQUE LIBERADO
                SC5->(RecLock("SC5",.F.))
             SC5->C5_I_STATU:= U_STPEDIDO() //Função de análise do pedido de vendas
             SC5->C5_I_BLOG := "S"
             If SC5->(FIELDPOS("C5_I_AGRUP")) > 0
                SC5->C5_I_AGRUP:=_cC5Agrupamento
             EndIf
             If !_lAmbTeste
                SC5->C5_I_LILO := Date()
             Else
                SC5->C5_I_LILO := _dHoje
             EndIf

                SC5->(MSUnLock())

             _aTelaPedidos[_nX,_nPosObs] := "1-Pedido LIBERADO"//ZPP->ZPP_OK:="LIBERADO"
             If _aTelaPedidos[_nX][_nPosTPCA] = "1"//PALITIZADO
                _nTotPalsLib+=_aTelaPedidos[_nX][_nPosPalete]
             Else
                _nTotPesoLib+=SC5->C5_I_PESBR
             EndIf

             nLiberados++
          Else          
             If lTemColCarga
                Disarmtransaction()//para quando é carga completa das mesos / Tem que ser antes pq o MOMS66ZY8() grava na base
                _lDisarmou:=.T.
             EndIf
                _aTelaPedidos[_nX,nPosCar] = "BR_AMARELO"//REJEITADO //ZPP->ZPP_OK:="REJEITADO"
             _SeqZY3:= MOMS66ZY3("005", _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) //FALTA DE ESTOQUE
             MOMS66ZY8("005",_SeqZY3, _dHoje, _cTime,_cVinc,_aSC6_Produtos)      //FALTA DE ESTOQUE
             _aTelaPedidos[_nX,_nPosObs] := "2-Pedido com problema na liberacao - Item: "+SC6->C6_PRODUTO+" - "+_cLogErro

             If lTemColCarga .And. _lDisarmou
                BREAK
             EndIf
          EndIf

       // PASTAS 1 , 2, 3 E DAS MESOS
       ElseIf _aTelaPedidos[_nX,nPosCar]   == "ENABLE" .AND.;// VERDE - Carregar SIM
              (_aTelaPedidos[_nX][nPosOK2] == "LBNO"   .Or. (lTemColCarga .And. Empty(_aTelaPedidos[_nX][nPosC1])))
                  // REAL - DESMARCADO                  OU  REAL MARCADO MAS SEM CARGA VALIDADA 

              _cJutificativa:="027"//PEDIDO FORA DO PADRAO PARA CARREGAMENTO           
              _aTelaPedidos[_nX,_nPosObs] := "3.4-Pedido fora do padrao para carregamento"

              If _aTelaPedidos[_nX,_nPosCaFechada] == "1-SIM"  //PASTA 1 E 2
              
                 _cJutificativa:="022"//NÃO CARREGOU POR DECISÃO DO COMERCIAL
                 _aTelaPedidos[_nX,_nPosObs] := "3.1-Pedido nao carregou por decisao do comercial"
              
              ElseIf lTemColCarga// PASTAS DA MESORREGIÕES
                 nMesoPeso:=0
                 For P := 1 TO Len(_aTelaPedidos)
                     If _aTelaPedidos[P][nPosCar] == "ENABLE" .AND.;// VERDE - Carregar SIM
                       (_aTelaPedidos[P][nPosOK2] == "LBNO"   .Or. (lTemColCarga .And. Empty(_aTelaPedidos[P][nPosC1])))
                        // REAL - DESMARCADO                  OU  REAL MARCADO MAS SEM CARGA VALIDADA 
                        nMesoPeso+=_aTelaPedidos[P][_nPosPesBru]//SC5->C5_I_PESBR
                     EndIf
                 Next  
                 If nMesoPeso > 0 .And. Round((nMesoPeso/1000),0) > Val(AllTrim(_cMultPeso))//Ex.: "14 / 30 / 46 / 50" Val() DEVVOLVE 14
                    _cJutificativa:="022"//NÃO CARREGOU POR DECISÃO DO COMERCIAL
                    _aTelaPedidos[_nX,_nPosObs] := "3.2-Pedido nao carregou por decisao do comercial"
                 Else
                    _cJutificativa:="021"//FALTA DE VOLUME PARA FORMAR CARGA
                    _aTelaPedidos[_nX,_nPosObs] := "3.3-Pedido nao carregou por falta de volume para formar carga"
                 EndIf

              EndIf

              If _lSimular
                 BREAK
              EndIf
              _SeqZY3:= MOMS66ZY3(_cJutificativa, _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) 
              MOMS66ZY8(_cJutificativa,_SeqZY3, _dHoje, _cTime,_cVinc,_aSC6_Produtos)      
   
       ElseIf _aTelaPedidos[_nX,_nPosEst] = "DISABLE" //FALTA DE ESTOQUE
       
          _aTelaPedidos[_nX,_nPosObs] := "4-Pedido nao carregou por falta de estoque"
          If _lSimular
             BREAK
          EndIf
          _SeqZY3:= MOMS66ZY3("005", _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) //FALTA DE ESTOQUE
          MOMS66ZY8("005",_SeqZY3, _dHoje, _cTime,_cVinc,_aSC6_Produtos)      //FALTA DE ESTOQUE // // GRAVA SÓ OS PRODUTOS QUE FALTOU ESTOQUE
       
       ElseIf _aTelaPedidos[_nX,_nPosCap] = "DISABLE" //SEM CAPACIDADE
          
          _aTelaPedidos[_nX,_nPosObs] := "5-Pedido nao carregou por falta de capacidade"
          If _lSimular
             BREAK
          EndIf
          MOMS66ZY3("002", _dHoje, _cTime,_cVinc,_aTelaPedidos,_nX) //FALTA DE CAPACIDADE
       
       EndIf

    End Sequence

    aAdd(_aColsTGrv,_aTelaPedidos[_nX])

Next

If _lGravaLOG
   oProc:cCaption := ("Processando: "+StrZero(nConta,5) +" de "+ _cTot+" - Liberados: "+CValToChar(nLiberados)+" - Gravando Log...")
   MOMS66LG("PEDIDOS",_aTelaPedidos,oProc,_cPasta,{},lTemColCarga)//GRAVA ITEM DA TELA
EndIf

Return  .T.

/*===============================================================================================================================
Programa----------: MOMS66TGrv
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Tela com resultado da Gravacao
Parametros--------: _aColsTGrv,oProc
Retorno-----------: NENHUM
===============================================================================================================================*/
Static Function MOMS66TGrv(_aColsTGrv,oProc)

Local _bSair :={|| oDlg2:End()  }
Local aHeader:=aHeaderP//{}
Local aBotoes:={}

If _lGravaLOG
   MOMS66LG("INICIAL" ,,oProc,"",_aSB2Inic   )//GRAVA STATUS INICIAL DA SB2
   MOMS66LG("FINAL"   ,,oProc,"",_aSB2       )//GRAVA ITEM DE CONSUMO DA SB2
EndIf

aBotoes:={}
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66Pesq(oMsMGet)           },"Pesquisando.."    ,"Aguarde..." )},"","PESQUISAR"        })
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("XLSX",O,oMsMGet)},"H.I. : "+TIME()+" - Aguarde...", "Gerando Excel (XLSX)..")},"","Exportacao para XLSX"})
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("XML" ,O,oMsMGet)},"H.I. : "+TIME()+" - Aguarde...", "Gerando Excel (XML).. ")},"","Exportacao para XML "})
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|O| MOMS66Excel("CSV" ,O,oMsMGet)},"H.I. : "+TIME()+" - Aguarde...", "Gerando Excel (CSV).. ")},"","Exportacao para CSV "})
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66PPV("S",oMsMGet)        },"Lendo Pedido..","Aguarde...")},"","Ver Pedido Monitor"   })
aAdd(aBotoes,{"",{|| FWMsgRun( ,{|| MOMS66PPV("D",oMsMGet)        },"Lendo Pedido..","Aguarde...")},"","Ver Pedido Detalhado" })
aAdd(aBotoes,{"",{|| MOMS66LEG(.T.,oMsMGet)                       },"","LEGENDAS"})

nLin01:=05
nLin02:=08 
nLin03:=25 
nCol01:=10

DEFINE MSDIALOG oDlg2 TITLE _cTitulo OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]

                                                     //Largura , ALTURA
    oPnlTopTop := TPanel():New( 1 , 0 , , oDlg2 , , , , , , 80 , 20 , .F. , .F. )

          @ nLin02-5,nCol01 Say "Saldo Inicial: " +("KG "+AllTrim(TRANS(_nPesSaldoIni,"@E 999,999,999,999.999"))) SIZE 099,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say "Qtde de Palete: "+(AllTrim(TRANS(_nPalSaldoIni,"@E 999,999,999,999.999")))       SIZE 099,009 OF oPnlTopTop PIXEL 	   
       nCol01+=35
       nCol01+=55
          @ nLin02-5,nCol01 Say oSAYPesLib PROMPT "Liberado: "+("KG "+AllTrim(TRANS( _nTotPesoLib,"@E 999,999,999,999.999"))) SIZE 099,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say oSAYPalLib PROMPT "Qtde Palete: "+(AllTrim(TRANS( _nTotPalsLib,"@E 999,999,999,999.999")))    SIZE 099,009 OF oPnlTopTop PIXEL 
       nCol01+=24
       nCol01+=55
          @ nLin02-5,nCol01 Say "Capacidade UN: " +("KG "+AllTrim(TRANS(_nCapacPes,"@E 999,999,999,999"))) SIZE 199,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say "Qtde de Palete: "+(AllTrim(TRANS(_nCapacPal,"@E 999,999,999,999")))           SIZE 199,009 OF oPnlTopTop PIXEL 
       nCol01+=38
       nCol01+=55
          @ nLin02-5,nCol01 Say oSAYVlGer PROMPT "Valor Gerou Financeiro: "+("R$ "+AllTrim(TRANS( _nTotGerFin,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 
          @ nLin02+5,nCol01 Say "Potencial Faturamento: "+("R$ "+AllTrim(TRANS( _nTotPonFat,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 
       nCol01+=55
       nCol01+=55
          @ nLin02-5,nCol01 Say oSAYPesNGer PROMPT "Peso Não Gerou Financeiro.:"+("KG "+AllTrim(TRANS(_nTotNaoGerFin,"@E 999,999,999,999.99"))) SIZE 199,009 OF oPnlTopTop PIXEL 

                                 //[ nTop]       , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle],cLinhaOk,cTudoOk,cIniCpos, [ aAlter, nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] 
    oMsMGet := MsNewGetDados():New((aPosObj[2,1]),aPosObj[2,2],aPosObj[2,3],aPosObj[2,4],GD_UPDATE ,        ,       ,        ,{"PO_OK"},         ,        ,            ,             ,          ,oDlg2   ,aHeader        ,_aColsTGrv,)

    oMsMGet:SetEditLine(.F.)
    oMsMGet:AddAction("PO_OK"   ,{|| MOMS66LEG(.T.,oMsMGet)  })
    oDlg2:lMaximized:=.T.
       
ACTIVATE MSDIALOG oDlg2 ON INIT (EnchoiceBar(oDlg2,_bSair,_bSair,,aBotoes),;
                                             oPnlTopTop:Align:=CONTROL_ALIGN_TOP,;
                                           oMsMGet:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT )

Return .T.

/*
===============================================================================================================================
Programa--------: Ver_Lib_PV(cChave)
Autor-----------: Alex Wallauer
Data da Criacao-: 26/09/2016
Descrição-------: Verefica se no SC9 esta tudo OK ou tenta liberar o Pedido
Parametros------: cChave: Filia + Pedido, _lLiberaPF: Se .T. tenta Liberar o Pedido senao só ver se ta liberado OK
Retorno---------: Lógico (.F.) Tá com erro (.T.) Tá tudo OK
===============================================================================================================================
*/
Static Function Ver_Lib_PV(cChave)

Local _lOK:=.T.//Não Tem erro
Local _nQtdLib:=0

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_ITEM+C6_PRODUTO
If !SC6->( DBSeek( cChave ) )
    _lOK:=.F.//TEM ERRO
    _cLogErro:="Nao achou SC6: "+cChave
    Return .F.
EndIf

SC9->(DBSetOrder(1))
SC6->(DBSetOrder(1))
While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == cChave
    
    If !SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
        _nQtdLib := MaLibDoFat(SC6->(RecNo()),SC6->C6_QTDVEN)//LIBERA ITEM DO PEDIDO
    EndIf
    
    If SC9->(DBSeek(SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM))
        If SC9->C9_QTDLIB <> SC6->C6_QTDVEN
            _cLogErro:="C9_QTDLIB diferente C6_QTDVEN"
            _lOK:=.F.//TEM ERRO
            Exit
        ElseIf !Empty(SC9->C9_BLEST)
            _lOK:=.F.//TEM ERRO
            _cLogErro:="C9_BLEST = "+SC9->C9_BLEST
            Exit
        EndIf	    
        If !(Empty(SC9->C9_BLCRED))
           SC9->(RecLock("SC9",.F.))
             SC9->C9_BLCRED := " "	   
              SC9->(MSUnLock("SC9"))
               
           //Faz análise e liberação de estoque pois o padrão não analisa estoque se o crédito está bloqueado
           //Posiciona SC6 pois a função A440VerSb2 depende do SC6 posicionado para analisar o estoque
           If SC6->(DBSeek(SC9->C9_FILIAL+SC9->C9_PEDIDO+SC9->C9_ITEM)) .And. A440VerSB2(SC9->C9_QTDLIB)
                 If !(Empty(SC9->C9_BLEST))
                    SC9->(RecLock("SC9",.F.))
                 SC9->C9_BLEST := ""
                    If !(MaAvalSC9("SC9",5,{{ "","","","",SC9->C9_QTDLIB,SC9->C9_QTDLIB2,Ctod(""),"","","",SC9->C9_LOCAL}}))
                       SC9->C9_BLEST := "02"
                    _lOK:=.F.//TEM ERRO
                    _cLogErro:="C9_BLEST = "+SC9->C9_BLEST
                    Exit
                    EndIf	
                 SC9->(MSUnLock("SC9"))
              EndIf
              EndIf	
           EndIf	

    Else
       _lOK:=.F.//TEM ERRO
       _cLogErro:="Nao achou SC9: "+SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM
       Exit
    EndIf
    SC6->( DBSkip() )
    
EndDo

Return _lOK

/*
===============================================================================================================================
Programa--------: MOMS66ZY3
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Grava as informações necessárias na tabela ZY3
Parametros------: cCodjus, _dHoje, _cTime, _cVinc,_aTelaPedidos,_nX
Retorno---------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66ZY3(cCodjus, _dHoje, _cTime, _cVinc,_aTelaPedidos,_nX)

Local _cSec := MOMS66SEC()

ZY3->(RecLock("ZY3", .T.))
ZY3->ZY3_FILIAL := xFilial("ZY3")
ZY3->ZY3_FILFT  := SC5->C5_FILIAL
ZY3->ZY3_NUMPV  := SC5->C5_NUM
ZY3->ZY3_SEQUEN := _cSec
ZY3->ZY3_DTMONI := _dHoje
ZY3->ZY3_HRMONI := _cTime
ZY3->ZY3_COMENT := "Processamento de Pedidos Pendentes (MOMS066)"
ZY3->ZY3_CODUSR := __cUserId
ZY3->ZY3_NOMUSR := UsrFullName(__cUserId)
ZY3->ZY3_ENCMON := "N"
ZY3->ZY3_DTNECE := SC5->C5_I_DTNEC
ZY3->ZY3_DTFAT  := _aTelaPedidos[_nX,_nPosNes]
ZY3->ZY3_DTFOLD := SC5->C5_I_DTENT
ZY3->ZY3_JUSCOD := cCodjus
ZY3->ZY3_ORIGEM := "MOMS066" 
ZY3->ZY3_VNCZY8 := (SC5->C5_NUM + _cVinc)
ZY3->(MSUnLock())

Return _cSec

/*
===============================================================================================================================
Programa--------: MOMS66ZY8
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Grava as informações necessárias na tabela ZY8 
Parametros------: cCodJus - Código da justificativa
Retorno---------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66ZY8(cCodjus,_cSeq, _dHoje, _cTime, _cVinc,_aSC6_Produtos)

Local I

For I := 1 TO Len(_aSC6_Produtos)
    If _aSC6_Produtos[I,2] //SE TEM ESTOQUE Loop
       Loop
    EndIf
    SC6->(DBGoTo(_aSC6_Produtos[I,1]))
    If SC6->(Deleted())
       Loop
    EndIf

    ZY8->(RecLock("ZY8", .T.))
    ZY8->ZY8_FILIAL := xFilial("ZY8")
    ZY8->ZY8_NUMPV  := SC6->C6_NUM
    ZY8->ZY8_SEQUEN := _cSeq
    ZY8->ZY8_DTMONI := _dHoje
    ZY8->ZY8_HRMONI := _cTime
    ZY8->ZY8_CODUSR := __cUserId
    ZY8->ZY8_NOMUSR := UsrFullName(__cUserId)
    ZY8->ZY8_CODPRD := SC6->C6_PRODUTO
    ZY8->ZY8_DSCPRD := SC6->C6_DESCRI 
    ZY8->ZY8_UNSVEN := SC6->C6_UNSVEN
    ZY8->ZY8_SEGUM  := SC6->C6_SEGUM
    ZY8->ZY8_QTDVEN := SC6->C6_QTDVEN
    ZY8->ZY8_UM     := SC6->C6_UM
    ZY8->ZY8_FILFT  := SC6->C6_FILIAL
    ZY8->ZY8_JUSCOD := cCodjus
    ZY8->ZY8_ORIGEM := "MOMS066" 
    ZY8->ZY8_VNCZY3 := (SC6->C6_NUM +  _cVinc)
    ZY8->(MSUnLock())
Next

Return

/*
===============================================================================================================================
Programa----------: MOMS66Excel
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Geracao de relatorio da tela
Parametros--------: _cTipo,oProc,oMsMGet
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66Excel(_cTipo As Character, oProc As Object, oMsMGet As Object) As Logical

Local _aParAux := {} , nI As Numeric , P As Numeric
Local _aParRet := {}
Local MV_SALVA1:=MV_PAR01 As Numeric
Local MV_SALVA2:=MV_PAR02 As Numeric
Private _cTitExcel:="Lista de Pedidos apos geração" As Character

MV_PAR01:=1
MV_PAR02:=3

If oMsMGet = NIL 

   _aOpcP:={"Atual"   ,"Todas"}
   _aOpcM:={"Marcados","Desmarcados","Todos"}

   aAdd( _aParAux , { 3 , "Pastas"       , MV_PAR01,_aOpcP, 60 , '' , .T. } )
   aAdd( _aParAux , { 3 , "Pedidos"      , MV_PAR02,_aOpcM, 60 , '' , .T. } )

   For nI := 1 To Len( _aParAux )
       aAdd( _aParRet , _aParAux[nI][03] )
   Next     


   If !ParamBox( _aParAux , "SELECIONE OS FILTROS DOS PEDIDOS" , _aParRet , {|| .T. } , , , , , , , .T. , .T. )
       Return .F.
   EndIf

   If ValType(MV_PAR01) = "C"
      MV_PAR01:=Val(MV_PAR01)
   EndIf
   If ValType(MV_PAR02) = "C"
      MV_PAR02:=Val(MV_PAR02)
   EndIf
   _cTitExcel:=""
   If MV_PAR02 = 1
      _cTitExcel:=" - Marcados"
   ElseIf MV_PAR02 = 2
      _cTitExcel:=" - Desmarcados" 
   EndIf
   
   If MV_PAR01 = 1//PASTA ATUAL

      _cTitExcel:="Lista de Pedidos da Pasta "+MOMS66Obj(.T.)[1]+_cTitExcel
      If (oMsMGet:=MOMS66Obj()) = NIL 
         Return .F.//Loop 
      EndIf
       aCols:=oMsMGet:aCols
       If Len(aCols) = 0 .Or. ValType(aCols[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
          Return .F.//Loop
       EndIf

    Else// TODAS AS PASTAS

       _cTitExcel:="Lista de Pedidos de Todas as Pastas"+_cTitExcel
       aCols:={}

         oProc:cCaption:="Lendo Pedidos Cargas TOP1..."
         ProcessMessages()
         aColsAux:=aClone(oBrwTOP1:aCols)
          If Len(aColsAux) > 0 .And. ValType(aColsAux[1][_nPosRecnos]) = "A"//LINHA EM BRANCO
             For P := 1 TO Len(aColsAux) 
                 aAdd(aCols,aClone(aColsAux[P]))
                 aCols[P,_nPosRGBR]:="Cargas TOP1 / "+aCols[P,_nPosRGBR]
             Next
          EndIf

         oProc:cCaption:="Lendo Pedidos Cargas Fechadas..."
         ProcessMessages()
         aColsAux:=aClone(oBrwCaFe:aCols)
          If Len(aColsAux) > 0 .And. ValType(aColsAux[1][_nPosRecnos]) = "A"//LINHA EM BRANCO
             For P := 1 TO Len(aColsAux) 
                 aAdd(aCols,aClone(aColsAux[P]))
                 aCols[P,_nPosRGBR]:="Cargas Fechadas / "+aCols[P,_nPosRGBR]
             Next
          EndIf

         oProc:cCaption:="Lendo Pedidos Pedidos Fora de Padrão..."
         ProcessMessages()
         aColsAux:=aClone(oBrwFORA:aCols)
          If Len(aColsAux) > 0 .And. ValType(aColsAux[1][_nPosRecnos]) = "A"//LINHA EM BRANCO
             For P := 1 TO Len(aColsAux) 
                 aAdd(aCols,aClone(aColsAux[P]))
                 aCols[P,_nPosRGBR]:="Pedidos Fora de Padrão / "+aCols[P,_nPosRGBR]
             Next
          EndIf

         For P := 1 TO Len(aPedsReg1) 
              If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg1[P] } )) > 0
                oProc:cCaption:="Lendo Pedidos "+aFoldReg1[P]
                ProcessMessages()
                oMsMGet:=aBrowses[nPos,2]
                aColsAux:=aClone(oMsMGet:aCols)
                For nI := 1 TO Len(aColsAux) 
                    aAdd(aCols,aClone(aColsAux[nI]))
                Next
             EndIf
         Next
         For P := 1 TO Len(aPedsReg2) 
              If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg2[P] } )) > 0
                oProc:cCaption:="Lendo Pedidos "+aFoldReg2[P]
                ProcessMessages()
                oMsMGet:=aBrowses[nPos,2]
                aColsAux:=aClone(oMsMGet:aCols)
                For nI := 1 TO Len(aColsAux) 
                    aAdd(aCols,aClone(aColsAux[nI]))//
                Next
             EndIf
         Next
         For P := 1 TO Len(aPedsReg3) 
              If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg3[P] } )) > 0
                oProc:cCaption:="Lendo Pedidos "+aFoldReg3[P]
                ProcessMessages()
                oMsMGet:=aBrowses[nPos,2]
                aColsAux:=aClone(oMsMGet:aCols)
                For nI := 1 TO Len(aColsAux) 
                    aAdd(aCols,aClone(aColsAux[nI]))
                Next
             EndIf
         Next
         For P := 1 TO Len(aPedsReg4) 
              If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg4[P] } )) > 0
                oProc:cCaption:="Lendo Pedidos "+aFoldReg4[P]
                ProcessMessages()
                oMsMGet:=aBrowses[nPos,2]
                aColsAux:=aClone(oMsMGet:aCols)
                For nI := 1 TO Len(aColsAux) 
                    aAdd(aCols,aClone(aColsAux[nI]))
                Next
             EndIf
         Next
         For P := 1 TO Len(aPedsReg5) 
              If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg5[P] } )) > 0
                oProc:cCaption:="Lendo Pedidos "+aFoldReg5[P]
                ProcessMessages()
                oMsMGet:=aBrowses[nPos,2]
                aColsAux:=aClone(oMsMGet:aCols)
                For nI := 1 TO Len(aColsAux) 
                    aAdd(aCols,aClone(aColsAux[nI]))
                Next
             EndIf
         Next
    EndIf

Else
   _cTitExcel:="Lista de Pedidos apos geração"
   aCols:=oMsMGet:aCols
   If Len(aCols) = 0 .Or. ValType(aCols[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
      Return .F.
   EndIf
EndIf

If Len(aCols) > 0
   If _cTipo = "DETI"
      MOMS66DET(oProc,aCols)//GERA O RELATÓRIO DETALHANDO OS DADOS POR ITENS.
   Else
      MOMS66GerExcel(_cTipo,aHeaderP,aCols,oProc)
   EndIf
EndIf
MV_PAR01:=MV_SALVA1
MV_PAR02:=MV_SALVA2
Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66GerExcel
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Geracao de relatorio da tela
Parametros--------: _cTipo,aHeader,aCols
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66GerExcel(_cTipo,aHeader,aCols,oProc)

Local H , C , nIncio:=1
Local aCabCSV:={}
Local _aCabXML:={}

aAdd(_aCabXML,{"Filial",2,1,.F.})
aAdd(aCabCSV,"Filial")

For H := nIncio TO Len(aHeader)
   // Alinhamento: 1-Left   ,2-Center,3-Right
   // Formatação.: 1-General,2-Number,3-Monetário,4-DateTime
   If aHeader[H,8] = "C" .Or. aHeader[H,2] $ ""
      //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
      aAdd(_aCabXML,{aHeader[H,1]     ,1           ,1         ,.F.})//ESQUERDA,GERAL
   ElseIf aHeader[H,2] = "TOT_PEDIDO"
      //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
      aAdd(_aCabXML,{aHeader[H,1]     ,3           ,3         ,.F.})//DIREITA,MONETARIO
   ElseIf aHeader[H,8] ="N" //"C5_I_PESBR/PES_S_ESTO/QTDE_PALETE"
      //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
      aAdd(_aCabXML,{aHeader[H,1]     ,3           ,2         ,.F.})//DIREITA,NUMERO 
   Else
      //           Titulo das Colunas ,Alinhamento ,Formatação, Totaliza?
      aAdd(_aCabXML,{aHeader[H,1]     ,2           ,1         ,.F.})//CENTRO,GERAL
   EndIf
   aAdd(aCabCSV,aHeader[H,1])
Next
aColsXML:={}
_nTotal:=Len(aHeader)
nMarcados:=0
nDesmarcados:=0
For H := nIncio TO Len(aCols)

   oProc:cCaption:="Lendo Pedidos Marcados: "+StrZero(nMarcados,7)+" - Desmarcados: "+StrZero(nDesmarcados,7)
   ProcessMessages()
   If aCols[H,nPosOK2] = "LBOK"
      nMarcados++
   ElseIf aCols[H,nPosOK2] = "LBNO"
      nDesmarcados++
   EndIf
   If MV_PAR02 = 1 //MARCADOS
      If aCols[H,nPosOK2] = "LBNO"
         Loop
      EndIf
   ElseIf MV_PAR02 = 2//DESMARCADOS
      If aCols[H,nPosOK2] = "LBOK"
         Loop
      EndIf
   EndIf
   aItem:={}
   aAdd(aItem,_cFilPrc)
   For C := nIncio TO _nTotal
      _cConteudo:=AllTrim(AllToChar(aCols[H,C]))
      If _cConteudo == "LBOK"
         aAdd(aItem,"Marcado")
      ElseIf _cConteudo == "LBNO"
         aAdd(aItem,"Desmarcado")
      ElseIf _cConteudo == "ENABLE"
         aAdd(aItem,"SIM")
      ElseIf _cConteudo == "DISABLE"
         aAdd(aItem,"NAO")
      ElseIf _cConteudo == "BR_PRETO"
         aAdd(aItem,"PRETO")
      ElseIf _cConteudo == "BR_BRANCO"
         aAdd(aItem,"BRANCO")
      ElseIf _cConteudo == "BR_CINZA"
         aAdd(aItem,"CINZA")
      ElseIf _cConteudo == "BR_AMARELO"
         aAdd(aItem,"AMARELO")
      Else
         aAdd(aItem,aCols[H,C])
      EndIf	
   Next
   aAdd(aColsXML,aItem)
Next

_cTitXML:=_cTitExcel+" / "+_cFilPrc+ " - " + AllTrim(FWFilialName(cEmpAnt,_cFilPrc,1))
If _cTipo = "CSV"
   DlgToExcel( { { "ARRAY" , _cTitXML , aCabCSV , aColsXML } } ) 
ElseIf _cTipo = "XML"
   U_ITGEREXCEL(,,_cTitXML,,_aCabXML,aColsXML)
ElseIf _cTipo = "XLSX" //Exportação para Excel (.XLSX)
   U_ITGEREXCEL(,,_cTitXML,,_aCabXML,aColsXML,,,,,,,,.T.)
EndIf

U_ITMsg("Geração Concluida!  ["+DToC(DATE())+"] ["+TIME()+"]")

Return

/*
===============================================================================================================================
Programa----------: MOMS66PPV
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Função para visualizar Pedidos de Vendas Simples ou Detalhado
Parametros--------: _cTela
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66PPV(_cTela,oMsMGet)

If oMsMGet = NIL .And. (oMsMGet:=MOMS66Obj()) = NIL 
   Return ""
EndIf

If oMsMGet <> NIL
   aCols:=oMsMGet:aCols
   If Len(aCols) = 0 .Or. ValType(aCols[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
      Return ""
   EndIf
   N:=oMsMGet:oBrowse:nAt
   C:=oMsMGet:oBrowse:nColPos
Else
   Return ""
EndIf

DBSelectArea("SC5")
SC5->( DBSetOrder(1) )
If SC5->( DBSeek( _cFilPrc + aCols[n][_nPosPed] ) ) 
   If _cTela = "D"
      MatA410(Nil, Nil, Nil, Nil, "A410Visual")
   ElseIf _cTela = "S"
      MOMS66Visualiza("SC5",SC5->(RECNO()))
   EndIf
EndIf

Return ""

/*
===============================================================================================================================
Função------------: MOMS66LG
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Grava movimentação da SB2 
Parametros--------: cTipo,_aTelaPedidos,oProc,_cPasta,_aSB2,lTemColCarga,_aGerentes
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66LG(cTipo,_aTelaPedidos,oProc,_cPasta,_aSB2,lTemColCarga,_aGerentes)

Local _nX := 0
Default _aSB2:={}

If oProc <> NIL
   oProc:cCaption := ("Gravando LOG do tipo: "+cTipo)
   ProcessMessages()
EndIf
If  Len(_aSB2) > 0
    For _nX := 1 TO Len(_aSB2)

        ZPQ->(RecLock("ZPQ",.T.))
        ZPQ->ZPQ_FILIAL := _cFilPrc
        ZPQ->ZPQ_DATA   := Date()
        ZPQ->ZPQ_HORA   := _cTime 
        ZPQ->ZPQ_TIPO   := cTipo//"INICIAL" OU "FINAL"
        ZPQ->ZPQ_PRODUT := _aSB2[_nX][2]
        ZPQ->ZPQ_QATU   := _aSB2[_nX][3]  
        ZPQ->ZPQ_RESERV := _aSB2[_nX][4]
        ZPQ->ZPQ_EMPEN  := _aSB2[_nX][5]
        ZPQ->ZPQ_SALDO  := _aSB2[_nX][6] 
        ZPQ->ZPQ_LOCAL  := _aSB2[_nX][7] 
        ZPQ->ZPQ_QNPT   := _aSB2[_nX][8] 		
        ZPQ->(MSUnLock())

    Next
EndIf

If cTipo = "PEDIDOS"
    For _nX := 1 TO Len(_aTelaPedidos)

        If _aTelaPedidos[_nX,nPosCar] = "BR_BRANCO" 
           Loop
        EndIf

        ZPP->(RecLock("ZPP",.T.))
        ZPP->ZPP_FILIAL:= _cFilPrc
        ZPP->ZPP_DATA  := Date()
        ZPP->ZPP_HORA  := _cTime

        If _aTelaPedidos[_nX,nPosCar] == "BR_AMARELO"		   
           ZPP->ZPP_OK:="REJEITADO"	   

        ElseIf _aTelaPedidos[_nX,nPosCar]  $ "BR_PRETO/BR_CINZA"		   
           ZPP->ZPP_OK:="REAGENDADO"	   

        ElseIf _aTelaPedidos[_nX,nPosCar]    == "ENABLE" .AND.;//CARREGAR = SIM
           _aTelaPedidos[_nX,nPosOK2]        == "LBOK"   .AND.;//REAL - MARCADO
          (!lTemColCarga .Or. !Empty(_aTelaPedidos[_nX][nPosC1]) )
    //MARCADO PASTAS 1,2  OU  MARCADO COM CARGA VALIDADA
          
           ZPP->ZPP_OK:="LIBERADO"

        ElseIf _aTelaPedidos[_nX,nPosCar]   == "ENABLE" .AND.;//CARREGAR = SIM
              (_aTelaPedidos[_nX][nPosOK2] == "LBNO"   .Or. (lTemColCarga .And. Empty(_aTelaPedidos[_nX][nPosC1])))
                  // REAL - DESMARCADO                  OU  REAL MARCADO MAS SEM CARGA VALIDADA NA MESO

              If _aTelaPedidos[_nX,_nPosObs] = "3.1-"//_aTelaPedidos[_nX,_nPosCaFechada] == "1-SIM"  //PASTA 1 E 2
                 ZPP->ZPP_OK:="DESMARCADO" //"3.1-Pedido nao carregou por decisao do comercial"
              
              ElseIf _aTelaPedidos[_nX,_nPosObs] = "3.2-"//PASTAS DA MESORREGIÕES
                 ZPP->ZPP_OK:="DESMARCADO" //"3.2-Pedido nao carregou por decisao do comercial"

              ElseIf _aTelaPedidos[_nX,_nPosObs] =  "3.3-"// PASTAS DA MESORREGIÕES
                 ZPP->ZPP_OK:="FALTAVOLUME" //"3.3-Pedido nao carregou por falta de volume para formar carga"
              EndIf
       
       ElseIf _aTelaPedidos[_nX,_nPosEst] = "DISABLE" //FALTA DE ESTOQUE
          ZPP->ZPP_OK:="FALTAESTOQUE"    //"3.1-Pedido nao carregou por falta de estoque"
       ElseIf _aTelaPedidos[_nX,_nPosCap] = "DISABLE" //SEM CAPACIDADE
          ZPP->ZPP_OK:="FALTACAPACIDADE" //"3.2-Pedido nao carregou por falta de capacidade"
       EndIf	   
       If Empty(ZPP->ZPP_OK)
          ZPP->ZPP_OK:="NAOPROCESSADO"	   
       EndIf
        If _lSimular
          ZPP->ZPP_OK:="S"+ZPP->ZPP_OK
       EndIf
        ZPP->ZPP_PEDIDO :=   _aTelaPedidos[_nX,_nPosPed]
        ZPP->ZPP_ORDEMC :=   StrZero(_aTelaPedidos[_nX,_nPosOrdem],4)//StrZero(_aTelaPedidos[_nX,_nPosORC],4)
        ZPP->ZPP_ORDEMA :=   StrZero(_aTelaPedidos[_nX,_nPosOrdem],4)
        ZPP->ZPP_EMISSA :=   _aTelaPedidos[_nX,_nPosEms]
        ZPP->ZPP_DTENT  :=   _aTelaPedidos[_nX,_nPosEnt]
        ZPP->ZPP_QTDA   :=   StrZero(_aTelaPedidos[_nX,_nPosReg],2)
        ZPP->ZPP_DTNECE :=   _aTelaPedidos[_nX,_nPosNes]
        ZPP->ZPP_AGEND  :=   _aTelaPedidos[_nX,_nPosTpA]
        ZPP->ZPP_ESTOQ  :=If(_aTelaPedidos[_nX,_nPosEst]="ENABLE","Com Estoque"   ,"Sem Estoque")
        ZPP->ZPP_CAPACI :=If(_aTelaPedidos[_nX,_nPosCap]="ENABLE","Com Capacidade","Sem Capacidade")
        ZPP->ZPP_OPER   :=   _aTelaPedidos[_nX,_nPosTpO] 
        ZPP->ZPP_TPFRET :=   _aTelaPedidos[_nX,_nPosTpF]
        ZPP->ZPP_PEVIN  :=   _aTelaPedidos[_nX,_nPosPedVin] 
        ZPP->ZPP_OBSERV :=   _aTelaPedidos[_nX,_nPosObs]
        ZPP->ZPP_CONTRO :=   _aTelaPedidos[_nX,_nPosChave]
        If ZPP->(FIELDPOS("ZPP_PASTA")) > 0 
           ZPP->ZPP_PASTA:=  _cPasta+"("+_aTelaPedidos[_nX,_nPosRGBR]+" /"+_aTelaPedidos[_nX,_nPosMeso]+")"
        EndIf
        ZPP->(MSUnLock())

    Next

EndIf

Return .T.

/*
===============================================================================================================================
Função------------: MOMS66LEG
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: LEGENDAS
Parametros--------: lPosGrv,oMsMGet
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66LEG(lPosGrv,oMsMGet)

Local aLegenda:={}
Local N , aCols , C

If lPosGrv
   aAdd(aLegenda,{"ENABLE"    ,"Liberados"                         })
   aAdd(aLegenda,{"DISABLE"   ,"Não Processados"                   })
   aAdd(aLegenda,{"BR_AMARELO","Rejeitados na Liberação"           })
   aAdd(aLegenda,{"BR_PRETO"  ,"Reagendados"                       })
   aAdd(aLegenda,{"BR_CINZA"  ,"Reagendados"                       })
   aAdd(aLegenda,{"BR_BRANCO" ,"Agendamentos futuro"               })
Else
   aAdd(aLegenda,{"ENABLE"    ,"Sim / Com Estoque / Com Capacidade"})
   aAdd(aLegenda,{"DISABLE"   ,"Não / Sem Estoque / Sem Capacidade"})
   aAdd(aLegenda,{"BR_PRETO"  ,"Fora da Data e será Reagendado"    })
   aAdd(aLegenda,{"BR_CINZA"  ,"Pedido Vinculado com problema"     })
   aAdd(aLegenda,{"BR_BRANCO" ,"Agendamento futuro"                })
   aAdd(aLegenda,{"BR_AMARELO","Pedido excluido"                   })
EndIf

BrwLegenda("PEDIDOS","Legenda",aLegenda)

If oMsMGet = NIL .And. (oMsMGet:=MOMS66Obj()) = NIL 
   Return "BR_AZUL"
EndIf

If oMsMGet <> NIL
   aCols:=oMsMGet:aCols
   If Len(aCols) = 0 .Or. ValType(aCols[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
      Return "BR_AZUL"
   EndIf
   N:=oMsMGet:oBrowse:nAt
   C:=oMsMGet:oBrowse:nColPos
   _cRet:=aCols[N][C]//RETORNA O CONTEUDO DELE MESMO 
   Return _cRet//RETORNA O CONTEUDO DELE MESMO 
EndIf

Return "BR_AZUL"//Se devolver azul é pq deu KAKA


/*
===============================================================================================================================
Programa----------: MOMS66CT
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Retorna a Carga Total = ao relatorio de Ordem de Carga
Parametros--------: _cProduto: SC6->C6_PRODUTO , _nQtde: SC6->C6_QTDVEN , 
                   lInicial: USADO PARA CALCULAR O SALDO INICIAL NO SC9
                   _cC5_I_TIPCA: C5_I_TIPCA
Retorno-----------: Carga Total
===============================================================================================================================
*/
Static Function MOMS66CT(_cProduto,_nQtde,lInicial,_cC5_I_TIPCA)

Local _nQtPalete:= 0
Default _cC5_I_TIPCA:= ""

//A ordem foi setada no inicio do programa
If !SB1->(DBSeek(xFilial()+_cProduto))
   _cPaletFechado:="2-NAO"
   Return 0
EndIf

// Cálculo da quantidade de Paletes
If SB1->B1_I_UMPAL == '1'
    _nQtPalete	:= ( _nQtde / SB1->B1_I_CXPAL )
    _cUMPal:= cValToChar( SB1->B1_I_CXPAL  ) +' '+SB1->B1_UM
   
ElseIf SB1->B1_I_UMPAL == '2'

    If AllTrim(SB1->B1_SEGUM) == "PC" .And. AllTrim(SB1->B1_TIPO) == "PA" //Tratamento para o QUEIJO
       _nQtPalete	:= (  _nQtde  / SB1->B1_I_CXPAL )
    Else
       _nQtPalete	:= ( MOMS66CNV( _nQtde , 1 , 2 ) / SB1->B1_I_CXPAL )
    EndIf
    _cUMPal:= cValToChar( SB1->B1_I_CXPAL  ) +' '+SB1->B1_SEGUM
    
ElseIf SB1->B1_I_UMPAL == '3'

    _nQtPalete:= ( MOMS66CNV( _nQtde , 1 , 3 ) / SB1->B1_I_CXPAL )
    _cUMPal   := cValToChar( SB1->B1_I_CXPAL  ) +' '+SB1->B1_I_3UM

Else
    _cUMPal:= ''
    _nQtPalete:= 0
EndIf

If lInicial//USADO PARA CALCULAR O SALDO INICIAL NO SC9
   Return _nQtPalete//COM Decimal
EndIf

If _nQtPalete <> Int(_nQtPalete) .Or. _cC5_I_TIPCA = "2" //Batida
   _cPaletFechado:="2-NAO"
EndIf

If _nQtPalete = Int(_nQtPalete) .And. (AllTrim(MV_PAR03) = "SP02")
   _cPaletFechado:="1-SIM"
EndIf

Return _nQtPalete

/*
===============================================================================================================================
Programa----------: MOMS66CNV
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Função para conversão entre unidades de medida - COPIA DA ROMS004CNV
Parametros--------: _nQtdAux , _nUMOri , _nUMDes
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66CNV( _nQtdAux , _nUMOri , _nUMDes )

Local _nRet	:= 0

Do Case

    Case _nUMDes == 1
        
        // Conversão da Segunda UM para a Primeira
        If _nUMOri == 2
            
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux * SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux / SB1->B1_CONV
            EndIf
        
        // Conversão da Terceira UM para a Primeira
        ElseIf _nUMOri == 3
            
            _nRet := _nQtdAux * SB1->B1_I_QT3UM
            
        EndIf
        
    Case _nUMDes == 2
        
        // Conversão da Primeira UM para a Segunda
        If _nUMOri == 1
            
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux * SB1->B1_CONV
            EndIf
        
        // Conversão da Terceira UM para a Segunda
        ElseIf _nUMOri == 3
            
            _nRet := _nQtdAux * SB1->B1_I_QT3UM
            
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nRet / SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nRet * SB1->B1_CONV
            EndIf
            
        EndIf
    
    Case _nUMDes == 3
    
        // Conversão da Primeira UM para a Terceira
        If _nUMOri == 1
            
            _nRet := _nQtdAux / SB1->B1_I_QT3UM
        
        // Conversão da Segunda UM para a Terceira
        ElseIf _nUMOri == 2
            
            If SB1->B1_TIPCONV == 'D'
                _nRet := _nQtdAux * SB1->B1_CONV
            ElseIf SB1->B1_TIPCONV == 'M'
                _nRet := _nQtdAux / SB1->B1_CONV
            EndIf
            
            _nRet := _nRet / SB1->B1_I_QT3UM
            
        EndIf

EndCase

Return( _nRet )

/*
===============================================================================================================================
Programa----------: MOMS66Item
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Tela dos itens do Pedido e dos itens que sobrou o estoque 
Parametros--------: cTela "ITENS" ou "CONSOLIDADO" ou "GERENTES" 
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66Item(cTela)

Local aCab       :={} , L
Local aSize      :={}
Local aItens     :={}
Local _aSC6_do_PV:={}

If (oMsMGet:=MOMS66Obj()) = NIL 
   Return ""
EndIf

If cTela = "GERENTES"
ElseIf cTela = "ITENS"

   aColsI:=oMsMGet:aCols
   If Len(aColsI) = 0
      Return .F.
   EndIf
   N:=oMsMGet:oBrowse:nAt
   If ValType(aColsI[N][_nPosRecnos]) <> "A"//LINHA EM BRANCO
      Return .F.
   EndIf
   _aSC6_do_PV:=aColsI[N][_nPosRecnos][2]

   aAdd(aCab,"")
   aAdd(aCab,"")
   aAdd(aCab,"Codigo")
   aAdd(aCab,"Produto")
   aAdd(aCab,"Local")
   aAdd(aCab,"Qtd 2 Um")
   aAdd(aCab,"Seg. Um")
   aAdd(aCab,"Qtd")
   aAdd(aCab,"Unidade")
   aAdd(aCab,"Qtd Palete")// (C6_I_QPALT)
   aAdd(aCab,"Vol. por Palete")
   aAdd(aCab,"Prc Unitário")
   aAdd(aCab,"Vlr Total")
   aAdd(aCab,"Qtd Atendida 2 Um") // (2ª UM)
   aAdd(aCab,"Qtd Sem Estoque 2 Um")//  (2ª UM)
   aAdd(aCab,"Peso Sem Estoque")
   aAdd(aCab,"Ger. Finan.")
   aAdd(aCab,"Registro")
   _nColRec:=Len(aCab)

   cPictQ:=AVSX3('C6_QTDVEN',6)
   cPictP:=AVSX3('C6_PRCVEN',6)
   SC6->(DBSetOrder(1))//SC6->C6_FILIAL+SC6->C6_NUM+SC6->C6_ITEM

   For L := 1 TO Len(_aSC6_do_PV)

         SC6->(DBGoTo(_aSC6_do_PV[L,1]))//MESMO DELETADO O GOTO Posiciona
       If SC6->(Deleted())
          Loop
       EndIf
       _cUMPal:=""//Preenchido dentro da Função MOMS66CT ()
       _nQtdePalete:=MOMS66CT(SC6->C6_PRODUTO,SC6->C6_QTDVEN,.F.)
       If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = "S"
          cFatura:="Sim"
       Else
          cFatura:="Nao"
       EndIf

       aItem:={}
       aAdd(aItem,.F. )
       aAdd(aItem,(_aSC6_do_PV[L,4]=0) )// QTDE FALTANTE
       aAdd(aItem,SC6->C6_PRODUTO)
       aAdd(aItem,AllTrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"B1_DESC")))
       aAdd(aItem,SC6->C6_LOCAL)
       aAdd(aItem,TRANS(SC6->C6_UNSVEN , cPictQ ))
       aAdd(aItem,SC6->C6_SEGUM)
       aAdd(aItem,TRANS(SC6->C6_QTDVEN , cPictQ ))
       aAdd(aItem,SC6->C6_UM)
       aAdd(aItem,TRANS(_nQtdePalete, "@E 9,999.999" ))//SC6->C6_I_QPALT
       aAdd(aItem,_cUMPal)
       aAdd(aItem,TRANS(SC6->C6_PRCVEN , cPictP ))
       aAdd(aItem,TRANS((SC6->C6_PRCVEN*SC6->C6_QTDVEN), cPictP ))
       aAdd(aItem,TRANS(_aSC6_do_PV[L,3],cPictQ) )//_nQtdeATend
       aAdd(aItem,TRANS(_aSC6_do_PV[L,4],cPictQ) )//_nQtdeFalta
       aAdd(aItem,TRANS(_aSC6_do_PV[L,5],cPictQ) )//_nPesoFalta
       aAdd(aItem,cFatura) 
       aAdd(aItem,_aSC6_do_PV[L,1])
       
       aAdd(aItens,aItem)
   Next
   If Len(aItens) = 0
      U_ITMsg("Esse pedido já foi Excluido do sistema.",'Atenção!',"",3)  
      Return ""
   EndIf
   _cTitulo:='ITENS DO PEDIDO: '+SC6->C6_NUM
   _cMsgTop:=NIL
    _bCondMarca:={|oLbxAux,nAt| !oLbxAux:aArray[nAt][2] }

    While .T.
                      //          ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
       _lRet:=U_ITListBox(_cTitulo,aCab,aItens, .T.    , 2    ,_cMsgTop ,          ,aSize  ,         ,     ,        ,          ,       ,        ,          , _bCondMarca,         ,       ,         )
       
       If _lRet 
          If !MOMS66Acesso()
             Loop
          EndIf
    
          // Grava o Array _aItensCorta com todos os itens de um pedidos de vendas para atualização da base de dados
          _aItensCorta:={}
          _aCortaRes:={}
          For L := 1 TO Len(aItens)
             If aItens[L,1] .And. !aItens[L,2]
                SC6->(DBGoTo(aItens[L,_nColRec]))
                aAdd(_aItensCorta,{SC6->C6_FILIAL ,;//01
                                 SC6->C6_NUM      ,;//02
                                 SC6->C6_ITEM     ,;//03
                                 SC6->C6_PRODUTO  ,;//04
                                 SC6->C6_LOCAL    ,;//05
                                 SC6->C6_QTDVEN   ,;//06
                                 "S"              ,;//07
                                 SC6->C6_UNSVEN    ;//08
                                 })
                  
             EndIf
          Next    

          If Len(_aItensCorta) > 0 .And. U_ITMsg("CONFIRMA A EXCLUSAO DOS PRODUTOS SELECIONADOS DO PEDIDO ?",'Atenção!',,3,2,2) .And. MOMS66Motivo()
             _aCortaRes:={}
             _cRetorno:=""
             FWMsgRun( ,{|oProc| _cRetorno:=MOMS047QGR(SC6->C6_FILIAL+SC6->C6_NUM,oProc,_aItensCorta) },"Processando!","Aguarde...") //ALTERA O PEDIDO MSEXECAUTO()

             If Len(_aCortaRes) = 0 
                For L := 1 TO Len(aItens)
                    If aItens[L,1] .And. !aItens[L,2]	     
                       aItem:={}
                       
                       aAdd(aItem,("SUCESSO" $ _cRetorno))
                       aAdd(aItem,aItens[L,3])
                       aAdd(aItem,aItens[L,4])
                       aAdd(aItem,_cRetorno  )
                       
                       aAdd(_aCortaRes,aItem)
                    EndIf
                Next		 
             EndIf

             If Len(_aCortaRes) > 0 
                aCab2:={}
                aAdd(aCab2,"")
                aAdd(aCab2,"Codigo")
                aAdd(aCab2,"Produto")
                aAdd(aCab2,"Mensagem")
                _nColMen:=Len(aCab2)
                  
                 aBotoesM:={}
                 aAdd(aBotoesM,{"",{|| U_ITMsgLog(oLbxAux:aArray[oLbxAux:nAt][ _nColMen ], "MENSAGEM" )},"","MENSAGEM"} )
                 _bDblClk:={|oLbxAux| U_ITMsgLog(oLbxAux:aArray[oLbxAux:nAt][ _nColMen ], "MENSAGEM" )}
                 
                 _cTitulo:='RESULTADO DO CORTE - '+_cTitulo
                                  //          ,_aCols    ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
                 If !U_ITListBox(_cTitulo,aCab2,_aCortaRes, .T.    , 4    ,        ,          ,        ,         ,     ,        , aBotoesM  ,       ,_bDblClk,           ,          ,         ,       ,          )
                    Loop
                 EndIf 
             Else
                 U_ITMsg("Nenhum produto selecionado.",'Atenção!',"Selecione 1 ou mais produtos",2)	      
                 Loop 	      
             EndIf  

          ElseIf Len(_aItensCorta) = 0 
             U_ITMsg("Nenhum produto selecionado.",'Atenção!',"Selecione 1 ou mais produtos",2)
             Loop
          Else
             Loop
          EndIf   
       EndIf
       
       Exit
    
    EndDo

ElseIf cTela = "CONSOLIDADO"

   aAdd(aCab,""       )                      //01   
   aAdd(aCab,"Codigo" )                      //02   
   aAdd(aCab,"Produto")                      //03   
   aAdd(aCab,"Local"  )                      //04   
   aAdd(aCab,"Qtde Disponivel 2a UM Inicial")//05                         
   aAdd(aCab,"2a UM"  )                      //06   
   aAdd(aCab,"Qtde Carteira 2a UM")          //07               
   aAdd(aCab,"Saldo 2a UM")                  //08       
   aAdd(aCab,"Qtde Disponivel 2a UM Final")  //09                       
   //aAdd(aCab,"Qtde Reserva Gerentes 1um")    //10                     
   
   cPictQ:=AVSX3('B2_QATU',6)
   
   For L := 1 TO Len(_aSB2)
       aItem:={}

        //Carrega fator de conversão se existir
        _nfator := 1
        If SB1->(DBSeek(xFilial("SB1")+_aSB2[L,2]))
           If SB1->B1_CONV == 0
              If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                    _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
              EndIf
           Else
              _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
           EndIf
        EndIf
       
       _aSB2[L,10]:= (_aSB2[L,11]*_nfator)-_aSB2[L,09] //SALDO
       
       aAdd(aItem,(_aSB2[L,10]>=0) )//01
       aAdd(aItem,_aSB2[L,2]     )//02
       aAdd(aItem,SB1->B1_DESC   )//03
       aAdd(aItem,_aSB2[L,7]     )//04
       aAdd(aItem,TRANS( (_aSB2[L,11]*_nfator) , cPictQ ))//05 DISPONIVEL INICIAL
       aAdd(aItem,SB1->B1_SEGUM  )//06
       aAdd(aItem,TRANS( _aSB2[L,09] , cPictQ ))//07 QTDE Carteira
       aAdd(aItem,TRANS( _aSB2[L,10] , cPictQ ))//08 SALDO
       aAdd(aItem,TRANS((_aSB2[L,06]*_nfator) , cPictQ ))//09 DISPONIVEL FINAL
       aAdd(aItens,aItem)
   Next

    aItens := aSort(aItens,,,{|x,y| x[3] < y[3]})

   _cTitulo:='SALDO CONSOLIDADO DO ESTOQUE DE TODOS OS ITENS DOS PEDIDOS LISTADOS'
   _cMsgTop:=NIL

           //          ,_aCols     ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
   U_ITListBox(_cTitulo,aCab,aItens, .T.    , 4    ,_cMsgTop ,          ,aSize  ,         ,     ,        ,          ,       ,        ,          ,           ,         ,       ,         )

ElseIf cTela = "PEDXPRODSEST"

   aAdd(aCab,"Filial"    )                   //01     
   aAdd(aCab,"Pedido"    )                   //02     
   aAdd(aCab,"Cliente"   )                   //03
   aAdd(aCab,"Rede"      )                   //04
   aAdd(aCab,"Gerente"   )                   //05
   aAdd(aCab,"Coord."    )                   //06
   aAdd(aCab,"UF Cliente")                   //07
   aAdd(aCab,"Codigo" )                      //08   
   aAdd(aCab,"Produto")                      //09   
   aAdd(aCab,"Local"  )                      //10   
   aAdd(aCab,"Qtde 2a UM Ped")               //11       
   aAdd(aCab,"2a UM"  )                      //12   
   aAdd(aCab,"Qtde Carteira 2a UM")          //13               
   aAdd(aCab,"Qtde Disponivel 2a UM Inicial")//14                         
   aAdd(aCab,"Sem Estoque?")                 //15                         
   
   cPictQ:=AVSX3('C6_QTDVEN',6)
   For L := 1 TO Len(_aPedXProdSE)
       If ValType(_aPedXProdSE[L,11]) = "N"
          _aPedXProdSE[L,11] := TRANS(  _aPedXProdSE[L,11], cPictQ )//Qtde 2a UM Ped
       EndIf
   Next
   cPictQ:=AVSX3('B2_QATU',6)
   
   For L := 1 TO Len(_aPedXProdSE)
       
        If (_nPos:=aScan(_aSB2, {|x| x[1] == _aPedXProdSE[L,1]  .And. x[2] == _aPedXProdSE[L,8] .And. x[7] = _aPedXProdSE[L,10] })) > 0
           //Carrega fator de conversão se existir
           _nfator := 1
           If SB1->(DBSeek(xFilial("SB1")+_aSB2[_nPos,2]))
              If SB1->B1_CONV == 0
                 If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                       _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                 EndIf
              Else
                 _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
              EndIf
           EndIf
          _aPedXProdSE[L,13] := TRANS(  _aSB2[_nPos,09]          , cPictQ )//QTDE CARTEIRA
          _aPedXProdSE[L,14] := TRANS( (_aSB2[_nPos,11]*_nfator) , cPictQ )//DISPONIVEL INICIAL
       Else
        _nfator := 1//_aPedXProdSE[L,11] := TRANS(  _aPedXProdSE[L,11]       , cPictQ )//Qtde 2a UM Ped
       EndIf
       
   Next

   _cTitulo:='PEDIDOS X PRODUTOS SEM ESTOQUE'
   _cMsgTop:=NIL

           //               ,_aCols      ,_lMaxSiz,_nTipo,_cMsgTop, _lSelUnc ,_aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab ,bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk)
   U_ITListBox(_cTitulo,aCab,_aPedXProdSE, .T.    , 1    ,_cMsgTop ,          ,aSize  ,         ,     ,        ,          ,       ,        ,          ,           ,         ,       ,         )

EndIf

Return ""

/*
===============================================================================================================================
Programa----------: MOMS66Pesq
Autor-------------: Alex Wallauer Ferreira
Data da Criacao---: 28/06/2022
Descrição---------: Pesquisa Pedidos
Parametros--------: oMsMGet
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS66Pesq(oMsMGet)

Local _oGet1		:= Nil
Local _oDlg			:= Nil
Local _cGet1		:= Space(Len(SC5->C5_NUM))
Local _aComboBx1	:= { "1 - Pedido" , "2 - Linha Com." }
Local _cComboBx1	:= "1 - Pedido"
Local _nOpca		:= 0
Local _nPos			:= 0
Local _lAchou		:= .F.

If oMsMGet = NIL .And. (oMsMGet:=MOMS66Obj()) = NIL 
   Return .F.
EndIf

If oMsMGet <> NIL
   aCols:=oMsMGet:aCols
   _cTotGeral:=AllTrim(Str(Len(aCols)))
Else
   Return .F.
EndIf

DEFINE MSDIALOG _oDlg TITLE "Pesquisar" FROM 178,181 TO 259,697 PIXEL 

@020,003 MsGet _oGet1 Var _cGet1				Size 212,009 PIXEL OF _oDlg COLOR CLR_BLACK Picture "@!" F3 "SC5"

DEFINE SBUTTON FROM 004,227 Type 1 ENABLE ACTION ( _nOpca := 1 , _oDlg:End() ) OF _oDlg
DEFINE SBUTTON FROM 021,227 Type 2 ENABLE ACTION ( _nOpca := 0 , _oDlg:End() ) OF _oDlg

@004,003 ComboBox _cComboBx1 Items _aComboBx1	Size 213,010 PIXEL OF _oDlg

ACTIVATE MSDIALOG _oDlg CENTERED

If _nOpca == 1
   _cGet1 := AllTrim( _cGet1 )
   _cPasta:= ""
   If _cComboBx1 = "1"
            
      If (_nPos := aScan(aCols,{|P| P[_nPosPed] == _cGet1 }) ) <> 0 // Procura o pedido na pasta atual
           oMsMGet:oBrowse:nAt    := N :=_nPos
         oMsMGet:oBrowse:nColPos:= C :=_nPosPed
           _lAchou:= .T.
         _cPasta:= "Atual"
      Else
         If (_nPos:=aScan(_aPedidos,{|aPed| aPed[_nPosPed] == _cGet1 } )) > 0 // Procura o pedido na lista geral dos Pedidos para ve se veio no filtro
            cPastaAtual:=MOMS66Obj(.T.)[1]//Nome da pasta 1 ou 2 ou meso
            cRegiaoBR  :=_aPedidos[_nPos,_nPosRGBR]
            cNomeMeso  :=_aPedidos[_nPos,_nPosMeso]
            _aPedPasta  := {}
            
            If cPastaAtual <> aFoders1[1]                                 // 1-"Cargas Fechadas TOP1"
               _aPedPasta:=oBrwTOP1:aCols
               If (_nPos:=aScan(_aPedPasta,{|aPed| aPed[_nPosPed] == _cGet1 } )) > 0    // Procura o pedido na pasta 1-"Cargas Fechadas TOP1"
                  _cPasta:= aFoders1[1]
                  _lAchou:=.T.
               EndIf
            EndIf
            
            If !_lAchou .And. cPastaAtual <>  aFoders1[2]                 // 2-"Cargas Fechadas"
               _aPedPasta:=oBrwCaFe:aCols
               If (_nPos:=aScan(_aPedPasta,{|aPed| aPed[_nPosPed] == _cGet1 } )) > 0    // Procura o pedido na pasta 2-"Cargas Fechadas"
                  _cPasta:= aFoders1[2]
                  _lAchou:=.T.
               EndIf
            EndIf

            If !_lAchou .And. cPastaAtual <>  aFoders1[3]                 // Pedidos Fora de Padrão
               _aPedPasta:=oBrwFORA:aCols
               If (_nPos:=aScan(_aPedPasta,{|aPed| aPed[_nPosPed] == _cGet1 } )) > 0    // Procura o pedido na pasta Pedidos Fora de Padrão
                  _cPasta:= aFoders1[3]
                  _lAchou:=.T.
               EndIf
            EndIf

            If !_lAchou .And. (_nPos:=aScan(aBrowses, {|B| B[1] == cNomeMeso } )) > 0// Cargas por Regioes do Brasil - Procura o nome da MESO
               oMsMGet2:=aBrowses[_nPos,2]
               _aPedPasta:=oMsMGet2:aCols
               If !Empty(_aPedPasta) .And. (_nPos:=aScan(_aPedPasta,{|aPed| aPed[_nPosPed] == _cGet1 } ) ) > 0 //Procura o pedido na lista de pedidos da aba dele
                  _cPasta:= cRegiaoBR+" / "+cNomeMeso
                  _lAchou:=.T.
               EndIf	  
               EndIf
         Else
            _lAchou:=.F.
         EndIf
      EndIf	  	
                
   ElseIf _cComboBx1 = "2"
                
      If (_nPos := aScan(aCols,{|P| P[_nPosOrdem] = Val(_cGet1) }) ) <> 0 
           oMsMGet:oBrowse:nAt    := N :=_nPos
         oMsMGet:oBrowse:nColPos:= C :=_nPosOrdem
           _lAchou:= .T.
      EndIf
                
    EndIf
Else
   Return .F.
EndIf

If _lAchou
   oMsMGet:oBrowse:Refresh()
   oMsMGet:oBrowse:SetFocus()
   If _cComboBx1 = "1"
      U_ITMsg("O Pedido "+_cGet1+" esta na linha "+AllTrim(Str(_nPos))+" da pasta "+_cPasta ,'Atenção!',,2) 
   EndIf
Else
   If _cComboBx1 = "1"
      U_ITMsg("PEDIDO não encontrado em nenhuma pasta.",'Atenção!',"Tente outro pedido",3) 
   Else
      U_ITMsg("Linha não encontrada.",'Atenção!',"O numero maximo de linhas é "+_cTotGeral,3) 
   EndIf
EndIf

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66Visualiza
Autor-------------: Alex Wallauer
Data da Criacao---: 28/06/2022
Descrição---------: Visualiza PEDIDO SIMPLES
Parametros--------: cAlias,nReg
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS66Visualiza(cAlias,nReg)

Local aPosObj   := {}
Local aObjects  := {}
Local aSize     := {}
Local aInfo     := {}
Local aCpos	    := NIL//{"",""}
Local aAcho     := {}//NIL//{"",  "","",}
Local nInc //, _nI
Local _cAlias     := GetNextAlias()
aAdd(aAcho,"C5_I_IDPED")
aAdd(aAcho,"C5_CLIENTE")
aAdd(aAcho,"C5_LOJACLI")
aAdd(aAcho,"C5_I_NOME" )
aAdd(aAcho,"C5_I_FANTA")
aAdd(aAcho,"C5_I_NOMRD")
aAdd(aAcho,"C5_I_MUN  ")
aAdd(aAcho,"C5_I_EST"  )
aAdd(aAcho,"C5_I_BAIRR")
aAdd(aAcho,"C5_I_OBPED")
aAdd(aAcho,"C5_MENNOTA")
aAdd(aAcho,"C5_I_OPTRI")
aAdd(aAcho,"C5_I_PVREM")
aAdd(aAcho,"C5_I_PVFAT")
aAdd(aAcho,"C5_I_TRCNF")
aAdd(aAcho,"C5_I_FILFT")
aAdd(aAcho,"C5_I_FLFNC")
aAdd(aAcho,"C5_I_TAB")
aAdd(aAcho,"C5_I_DSCTB")
aAdd(aAcho,"NOUSER")

Private cCadastro := "Visualizacao do Monitor do PEDIDO: "+SC5->C5_NUM
Private aTela[0][0],aGets[0]

aRotina := {}
aAdd( aRotina , { "Pesquisar"	, "" , 0 , 1 } )
aAdd( aRotina , { "Visualizar"	, "" , 0 , 2 } )
nOpc:=2

//Cria variaveis M->????? da Enchoice
For nInc := 1 To SC5->(FCount())
    M->&(SC5->(FieldName(nInc))) := SC5->(FieldGet(nInc))
Next

_aAuxZY3:=ZY3->(DBSTRUCT())
_cCampo :="ZY3_JUSDES"//Inseri o Campo Virtual de Descrição
aAdd( _aAuxZY3 ,{  Getsx3cache(_cCampo,"X3_CAMPO")    ,;
                   Getsx3cache(_cCampo,"X3_TIPO")     ,;
                   Getsx3cache(_cCampo,"X3_TAMANHO")  ,;
                   Getsx3cache(_cCampo,"X3_DECIMAL")  })

_otemp := FWTemporaryTable():New(_cAlias,_aAuxZY3)
_otemp:AddIndex( "I1", {"ZY3_SEQUEN"} )
_otemp:Create()

DBSelectArea("ZY3")

ZY3->(DBSetOrder(1)) // ZY3_FILIAL+ZY3_NUMPV+ZY3_SEQUEN 
If ZY3->(DBSeek( xFilial("ZY3")+SC5->C5_NUM ))
   While ! ZY3->(Eof()) .And. xFilial("ZY3")+SC5->C5_NUM == ZY3->(ZY3_FILIAL+ZY3_NUMPV)
      (_cAlias)->(DBAPPEND())
      For nInc := 1 To (_cAlias)->(FCount())
          If (nPos:=ZY3->(FIELDPOS( (_cAlias)->( FieldName(nInc)) ))) <> 0 
             (_cAlias)->(FieldPut( nInc , ZY3->( FieldGet(nPos) )  ))
          EndIf
      Next 
      (_cAlias)->ZY3_JUSDES := Posicione("ZY5",1,xFilial("ZY5")+ZY3->ZY3_JUSCOD,"ZY5_DESCR") 
      ZY3->(DBSkip())
   EndDo
Else
   U_ITMsg("Pedido "+SC5->C5_NUM+" não tem historico.",'Atenção!',"",3)
EndIf

_aZY3:={}
For nInc := 1 to Len(_aAuxZY3)
    _cUsado:=Getsx3cache(_aAuxZY3[nInc][1],"X3_USADO")
    If X3USO(_cUsado) //.AND. Getsx3cache(_aAuxZY3[nInc][1],"X3_BROWSE") = "S"
       aAdd(_aZY3,{_aAuxZY3[nInc][1], Getsx3cache(_aAuxZY3[nInc][1],"X3_ORDEM")} )
    EndIf
Next
_aZY3:=aSort(_aZY3,,,{|X,Y| X[2] < Y[2] })//ORDEM DE ORDEM

aTB_Campos:={}
For nInc := 4 To Len(_aZY3)
    aAdd(aTB_Campos,{_aZY3[nInc,1],,;
                     Getsx3cache(_aZY3[nInc,1],"X3_TITULO"),;
                     Getsx3cache(_aZY3[nInc,1],"X3_PICTURE")})
Next

aSize := MsAdvSize()
aAdd( aObjects, { 100, 100, .T., .T. } )
aAdd( aObjects, { 200, 200, .T., .T. } )
aInfo := { aSize[ 1 ], aSize[ 2 ], aSize[ 3 ], aSize[ 4 ], 5, 5 }
aPosObj := MsObjSize( aInfo, aObjects,.T.)
lNoFolder:=.F.
DEFINE MSDIALOG oDlg1 TITLE cCadastro From aSize[7],0 TO aSize[6],aSize[5] OF oMainWnd PIXEL

   DBSelectArea("SC5")
   //      cAlias, nReg, nOpc, aCRA, cLetra, cTexto, aAcho, aPos     ,aCpos , nModelo, nColMens, cMensagem, cTudoOk, oWnd, lF3,lMemoria, lColumn, caTela, lNoFolder, lProperty
   EnChoice("SC5", nReg, nOpc,     ,       ,       , aAcho,aPosObj[1], aCpos,        ,         ,          ,        , oDlg1,   , .F.    ,        ,       , lNoFolder,          )
   
   DBSelectArea(_cAlias)		
   (_cAlias)->(DBGoTop())
   oMark:=MSSELECT():New(_cAlias,,,aTB_Campos,.F.,,aPosObj[2])

ACTIVATE MSDIALOG oDlg1 ON INIT EnchoiceBar(oDlg1,{|| oDlg1:End() },{|| oDlg1:End() },,)

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS047QGR
Autor-------------: Alex Wallauer
Data da Criacao---: 30/01/2020
Descrição---------: ALTERA O PEDIDO
Parametros--------: _cChave : Filial do pedido de vendas + Numero do pedido dew vendas , oProc , _aItensCorta
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS047QGR(_cChave,oProc,_aItensCorta)

Local _aCabPV  :={}
Local _aItemPV :={}
Local _aItensPV:={} 
Local _nI  , E

Begin Sequence
_aCabPV  :={}
_aItemPV :={}
_aItensPV:={}
cErro:=""

If oProc <> NIL
    oProc:cCaption := ("Alterando Pedido: "+_cChave)
    ProcessMessages()
EndIf

SC5->(DBSetOrder(1))
If !SC5->(DBSeek( _cChave ))
   cErro:="Pedido não encontrado: "+_cChave
   BREAK
EndIf

SC6->( DBSetOrder(12) )//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
If !SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
   cErro:="Itens do Pedido não encontrado: "+SC5->C5_FILIAL + SC5->C5_NUM
   BREAK
EndIf

// Monta o cabeçalho do pedido
aAdd( _aCabPV, { "C5_FILIAL"  	,SC5->C5_FILIAL  , Nil}) // filial
aAdd( _aCabPV, { "C5_NUM"    	,SC5->C5_NUM	 , Nil}) // Numero do Pedido de Vendas
aAdd( _aCabPV, { "C5_TIPO"	    ,SC5->C5_TIPO    , Nil}) // Tipo de pedido
aAdd( _aCabPV, { "C5_I_OPER" 	,SC5->C5_I_OPER  , Nil}) // Tipo da operacao
aAdd( _aCabPV, { "C5_CLIENTE"	,SC5->C5_CLIENTE , NiL}) // Codigo do cliente
aAdd( _aCabPV, { "C5_CLIENT" 	,SC5->C5_CLIENT	 , Nil}) // Cliente de Entregra
aAdd( _aCabPV, { "C5_LOJAENT"	,SC5->C5_LOJAENT , NiL}) // Loja Cliente de Entrega
aAdd( _aCabPV, { "C5_LOJACLI"	,SC5->C5_LOJACLI , NiL}) // Loja do cliente
aAdd( _aCabPV, { "C5_EMISSAO"	,SC5->C5_EMISSAO , NiL}) // Data de emissao
aAdd( _aCabPV, { "C5_TRANSP" 	,SC5->C5_TRANSP	 , Nil}) // Transpordadora
aAdd( _aCabPV, { "C5_CONDPAG"	,SC5->C5_CONDPAG , NiL}) // Codigo da condicao de pagamanto*
aAdd( _aCabPV, { "C5_I_TAB"  	,SC5->C5_I_TAB   , Nil}) // Tabela de preços
aAdd( _aCabPV, { "C5_VEND1"  	,SC5->C5_VEND1	 , Nil}) // Vendedor
aAdd( _aCabPV, { "C5_VEND2"  	,SC5->C5_VEND2	 , Nil}) // Coordenador
aAdd( _aCabPV, { "C5_VEND3"  	,SC5->C5_VEND3	 , Nil}) // Gerente
aAdd( _aCabPV, { "C5_MOEDA"	    ,SC5->C5_MOEDA   , Nil}) // Moeda
aAdd( _aCabPV, { "C5_MENPAD" 	,SC5->C5_MENPAD	 , Nil}) // Mensagem padrão para a nota
aAdd( _aCabPV, { "C5_LIBEROK"	,SC5->C5_LIBEROK , NiL}) // Liberacao Total
aAdd( _aCabPV, { "C5_TIPLIB"  	,SC5->C5_TIPLIB  , Nil}) // Tipo de Liberacao
aAdd( _aCabPV, { "C5_TIPOCLI"	,SC5->C5_TIPOCLI , NiL}) // Tipo do Cliente
aAdd( _aCabPV, { "C5_I_NPALE"	,SC5->C5_I_NPALE , NiL}) // Numero que originou a pedido de palete
aAdd( _aCabPV, { "C5_I_PEDPA"	,SC5->C5_I_PEDPA , NiL}) // Pedido Refere a um pedido de Palete
aAdd( _aCabPV, { "C5_I_DTENT"	,SC5->C5_I_DTENT , Nil}) // Dt de Entrega foi alterado para data do dia
aAdd( _aCabPV, { "C5_I_TRCNF"   ,SC5->C5_I_TRCNF , Nil}) // Troca Nota
aAdd( _aCabPV, { "C5_I_BLPRC"   ,SC5->C5_I_BLPRC , Nil}) // Bloqueio de Preços
aAdd( _aCabPV, { "C5_I_FILFT"   ,SC5->C5_I_FILFT , Nil}) // Filial de Faturamento
aAdd( _aCabPV, { "C5_I_FLFNC"   ,SC5->C5_I_FLFNC , Nil})
aAdd( _aCabPV, { "C5_FILGCT"    ,SC5->C5_FILGCT  , Nil})

// Monta o item do pedido
_nTotal:=0

While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
    
    _nI := aScan(_aItensCorta, {|x| x[1] == SC6->C6_FILIAL .AND.;
                                    x[2] == SC5->C5_NUM    .AND.;
                                    x[3] == SC6->C6_ITEM   .AND.;
                                    x[4] == SC6->C6_PRODUTO})
    If _nI > 0	
        
        _aItemPV:={}
        
        aAdd( _aItemPV , { "LINPOS"     ,"C6_ITEM"                           , SC6->C6_ITEM }) //  Informa a posição do item
        If _aItensCorta[_nI,7] = "S"
           aAdd( _aItemPV , { "AUTDELETA"  ,_aItensCorta[_nI,7]                 , Nil }) // Informa se o item será ou não excluído.
        EndIf
        aAdd( _aItemPV , { "C6_FILIAL"  , SC6->C6_FILIAL                     , Nil }) // Filial
        aAdd( _aItemPV , { "C6_NUM"     , SC6->C6_NUM	                     , Nil }) // Numero do Pedido de Vendas
        aAdd( _aItemPV , { "C6_PRODUTO" , SC6->C6_PRODUTO                    , Nil }) // Codigo do Produto
          If _aItensCorta[_nI,7] = "S"
           aAdd(_aItemPV,{ "C6_QTDVEN"  , SC6->C6_QTDVEN                     , Nil }) // 1oUM Quantidade 
           aAdd(_aItemPV,{ "C6_UNSVEN"  , SC6->C6_UNSVEN                     , Nil }) // 2oUM Quantidade 
        Else
           aAdd(_aItemPV,{ "C6_QTDVEN"  , _aItensCorta[_nI,6]                , Nil,,SC6->C6_QTDVEN }) // 1oUM Quantidade 
           aAdd(_aItemPV,{ "C6_UNSVEN"  , _aItensCorta[_nI,8]                , Nil,,SC6->C6_UNSVEN }) // 2oUM Quantidade 
        EndIf   
        aAdd( _aItemPV , { "C6_PRCVEN"  , SC6->C6_PRCVEN                     , Nil }) // Preco Unitario Liquido
        aAdd( _aItemPV , { "C6_PRUNIT"  , SC6->C6_PRUNIT                     , Nil }) // Preco Unitario Liquido
        aAdd( _aItemPV , { "C6_ENTREG"  , SC6->C6_ENTREG                     , Nil }) // Data da Entrega
        aAdd( _aItemPV , { "C6_LOJA"    , SC6->C6_LOJA	                     , Nil }) // Loja do Cliente
        aAdd( _aItemPV , { "C6_SUGENTR" , SC6->C6_SUGENTR                    , Nil }) // Data da Entrega
          If _aItensCorta[_nI,7] = "S"
           aAdd( _aItemPV , { "C6_VALOR"   , SC6->C6_VALOR                   , Nil }) // valor total do item
        Else
           aAdd( _aItemPV , { "C6_VALOR"   , Round((SC6->C6_PRCVEN*_aItensCorta[_nI,6]),2), Nil,,SC6->C6_VALOR  }) // valor total do item
        EndIf   
        aAdd( _aItemPV , { "C6_UM"      , SC6->C6_UM                         , Nil }) // Unidade de Medida Primar.
          If _aItensCorta[_nI,7] = "S"
           aAdd(_aItemPV,{ "C6_LOCAL"   , SC6->C6_LOCAL                      , Nil }) // Armazem / lmoxarifado  // SC6->C6_LOCAL
        Else
           aAdd(_aItemPV,{ "C6_LOCAL"   , _aItensCorta[_nI,5]                , Nil,,SC6->C6_LOCAL }) // Armazem / lmoxarifado  // SC6->C6_LOCAL
        EndIf   
        aAdd( _aItemPV , { "C6_DESCRI"  , SC6->C6_DESCRI                     , Nil }) // Descricao
        aAdd( _aItemPV , { "C6_QTDLIB"  , SC6->C6_QTDLIB                     , Nil }) // Quantidade Liberada
        aAdd( _aItemPV , { "C6_PEDCLI"  , SC6->C6_PEDCLI                     , Nil }) // Pedido do Cliente
        aAdd( _aItemPV , { "C6_I_BLPRC" , SC6->C6_I_BLPRC                    , Nil }) // Bloqueio de Preço
        
        aAdd( _aItensPV ,_aItemPV )

    EndIf
    _nTotal++
    
    SC6->( DBSkip() )
EndDo

SC6->( DBSetOrder(1) )//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM

lMsErroAuto   := .F.
_lMsgEmTela   := .F.
_cAOMS074Vld  := ""
_cAOMS074     := "MOMS066" //NAO MOSTRA MENSAGENS DO MATA410 / MT410TOK


If !MOMS66Travou(_aItensCorta,@cErro,.F.,oProc)
    BREAK
EndIf

If _nTotal = Len(_aItensCorta)//Exclui o pedido se For todos os itens
   _lExclui:=.T.
Else
   _lExclui:=.F.
EndIf

//_cMotivs:="01"//FALTA DE ESTOQUE
_cLocMot := _cMotivs

Begin Transaction

MSExecAuto( {|x,y,z| Mata410(x,y,z) } , _aCabPV , _aItensPV , If(_lExclui,5,4) )

End Transaction

_cMotivs:= _cLocMot

_nTotDepois:=0
SC6->( DBSetOrder(12) )//C6_FILIAL+C6_NUM+C6_PRODUTO+C6_SOLCOM
If !SC6->( DBSeek( SC5->C5_FILIAL + SC5->C5_NUM ) )
   While SC6->( !Eof() ) .And. SC6->( C6_FILIAL + C6_NUM ) == SC5->C5_FILIAL + SC5->C5_NUM
      _nTotDepois++
         SC6->( DBSkip() )
   EndDo
EndIf

If lMsErroAuto .Or. (_nTotDepois = _nTotal)//!Empty(_cAOMS074Vld)
   _cErro:=MostraErro(Upper(GetSrvProfString("STARTPATH","")),"MOMS066.LOG")
   _cErro:="[ Exclusão NÃO Realizada: ( "+_cAOMS074Vld + " ) (" + _cErro + ") ]"
Else
    _lEfetivar  := .F.//BLOQUEIA O BOTÃO GERAR
    lClicouMarca:= .T.//Ativa a atualização na troca de pasta
    _cErro:="[ Exclusão Realizada com SUCESSO ]"
EndIf

End Sequence

For E := 1 TO Len(_aCortaRes)
    If _cChave = _aCortaRes[E,2]+_aCortaRes[E,3]
       If lMsErroAuto
          _aCortaRes[E , 1 ] := .F.
          _aCortaRes[E , _nColMen ] := _cErro
       Else
          _aCortaRes[E , 1 ] := .T.
          _aCortaRes[E , _nColMen ] := _cErro
       EndIf
    EndIf
Next

Return _cErro

/*
===============================================================================================================================
Programa----------: MOMS66Travou()
Autor-------------: Alex Wallauer
Data da Criacao---: 09/10/2018
Descrição---------: Loca os registro de tabelas previamente, Tenta realizar lock de todos os registros por _nI segundos
Parametros--------: _aItensCorta: itens, _cErro: Mensagens erro,lSoLiberaPV,aTabelas
Retorno-----------: _ltravou: .T. / .F. 
===============================================================================================================================
*/
Static Function MOMS66Travou(_aItensCorta,_cErro,lSoLiberaPV,oProc,aTabelas)

Local _lIT_LOCKPD:= SuperGetMV('IT_LOCKPD',.T.,.F.)
Local _tini      := SECONDS()
Local _dini      := Date()
Local _ltravou   := .F.  
Local  _cMenAtual:=""
Default aTabelas :={"SC5","SB2"}//"SC6","SA1",
Default _cErro   :=""

If oProc <> NIL
   _cMenAtual:=oProc:cCaption
EndIf

While !(_ltravou)

   _tini:= SECONDS()
   _dini:= Date()
    
    While !(_ltravou) .And. (seconds() - _tini) < 10 .And. Date() == _dini
        
        _ltravou := .T.
        _cErro   := ""

        If oProc <> NIL
           oProc:cCaption := _cMenAtual+". Tentativa:  "+AllTrim( Str((SECONDS()-_tini)+1,2,0) ) 
           ProcessMessages()
        EndIf

        If aScan(aTabelas,"SC5") <>  0
            
            If !SC5->(MsRLock(SC5->(RECNO())))
                _cUser:= TCInternal(53)
                _cErro:= "PV esta em uso por "+_cUser
                _ltravou := .F.
                
            Else
                
                If  _lIT_LOCKPD
                    
                    SC5->(MSUnLockALL())
                    SC5->(MSUnLock())

                    
                EndIf
                
            EndIf
            
        EndIf
        
        If aScan(aTabelas,"SA1") <>  0
            
            SA1->(DBSetOrder(1))
            SA1->(DBSeek(SA1->(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI)))
            If  !SA1->(MsRLock(SA1->(RECNO())))
                _cUser:= TCInternal(53)
                _cErro := "Cliente esta uso: "+AllTrim(SC5->C5_CLIENTE + "/" + SC5->C5_LOJACLI)+" por "+_cUser
                _ltravou := .F.
                
            Else
                
                If  _lIT_LOCKPD
                    
                    SA1->(MSUnLockALL())
                    SA1->(MSUnLock())

                    
                EndIf
                
            EndIf
            
        EndIf
        
        If aScan(aTabelas,"SC6") <>  0 .Or. aScan(aTabelas,"SB2") <>  0
            
            SB2->(DBSetOrder(1))
            SC6->(DBSetOrder(1))
            SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
            
            While SC6->C6_NUM == SC5->C5_NUM .And. SC5->C5_FILIAL == SC6->C6_FILIAL .And. SC6->(!Eof())
                
                If aScan(aTabelas,"SC6") <>  0
                    If !SC6->(MsRLock(SC6->(RECNO())))
                        _cUser:= TCInternal(53)
                        _cErro := "Item do PV esta em uso: "+AllTrim(SC6->C6_FILIAL+"/"+SC6->C6_PRODUTO+"/ "+SC6->C6_LOCAL)+" por "+_cUser
                        _ltravou := .F.
                        
                    Else
                        
                        If  _lIT_LOCKPD
                            
                            SC6->(MSUnLockALL())
                            SC6->(MSUnLock())
                            
                        EndIf
                        
                    EndIf
                EndIf
                
                If aScan(aTabelas,"SB2") <>  0
                    
                    SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL))
                    
                    If !SB2->(MsRLock(SB2->(RECNO())))
                        _cUser:= TCInternal(53)
                        _cErro := "Produto / Armazem esta em uso: "+AllTrim(SC6->C6_PRODUTO)+" / "+SC6->C6_LOCAL+" por "+_cUser
                        _ltravou := .F.
                    Else
                        If  _lIT_LOCKPD
                            SB2->(MSUnLockALL())
                            SB2->(MSUnLock())
                        EndIf
                    EndIf
                    
                    If !lSoLiberaPV
                        
                        _nI := aScan(_aItensCorta, {|x| x[1] == SC6->C6_FILIAL .AND.;
                                                     x[2] == SC5->C5_NUM    .AND.;
                                                     x[3] == SC6->C6_ITEM   .AND.;
                                                      x[4] == SC6->C6_PRODUTO})
                        
                        If _nI > 0
                            
                            SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+_aItensCorta[_nI,5] ))
                            
                            If !SB2->(MsRLock(SB2->(RECNO())))
                                _cUser:= TCInternal(53)
                                _cErro := "Produto / Armazem esta em uso: "+AllTrim(SC6->C6_PRODUTO)+" / "+_aItensCorta[_nI,5]+" por "+_cUser
                                _ltravou := .F.
                            Else
                                If  _lIT_LOCKPD
                                    SB2->(MSUnLockALL())
                                    SB2->(MSUnLock())
                                EndIf
                            EndIf
                            
                            
                        EndIf
                    EndIf
                EndIf
                
                SC6->(DBSkip())
                
            EndDo
            
        EndIf
        
        If !_ltravou 
           Sleep(100) //Segura o processamento para testar no máximo 10 vezes por segundo os travamentos
        EndIf
    EndDo
    
    If !_ltravou .And. !lSoLiberaPV
       If U_ITMsg("Não foi possivel alocar os registros do PV: "+SC5->C5_NUM+" pq o "+_cErro ,;
                  'Atenção!',;
                  "Deseja TENTAR novamente alocar o PV ou FINALIZAR o processamento ?",3,2,3,,"TENTAR","FINALIZAR")//ALERT
          Loop
       Else
          Exit   
       EndIf		
    Else
       Exit
    EndIf
    
EndDo
If !Empty(_cErro)
   _cErro:="[ "+_cErro+" ]"
EndIf   
If oProc <> NIL
   oProc:cCaption := _cMenAtual
   ProcessMessages()
EndIf

Return _ltravou

/*
===============================================================================================================================
Programa----------: MOMS66Acesso()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
Descrição---------: Controle de acesso do ususario via ZZL
Parametros--------: NENHUM
Retorno-----------: .T. / .F. 
===============================================================================================================================
*/
Static Function MOMS66Acesso(_lEfetivar2)

Local _cFilAcesso:=AllTrim(SuperGetMV('IT_MOMS66FI',.T.,''))
Local lRet:=.T.
Default _lEfetivar2 := .T.//Default com .T. pq só no botão GERAR vai receber a variavel _lEfetivar2 para dar mensagem ou não.

ZZL->( DBSetOrder(3) )
If ZZL->( DBSeek( xFilial("ZZL") + RetCodUsr() ) )
   If !ZZL->ZZL_GESCPV = "S"
      If !_lAmbTeste
         U_ITMsg("USUARIO SEM ACESSO A ESSA ROTINA.",'Atenção!',"Solicite acesso a Area responsavel. [ZZL_GESCPV = 'S']",3) 
         lRet:=.F.
      EndIf
   EndIf
EndIf
ZZL->(DBSetOrder(1))

If lRet .And. !Empty(_cFilAcesso) .And. !_cFilPrc $ _cFilAcesso
   If !_lAmbTeste
      U_ITMsg("FILIAL "+_cFilPrc+" SEM ACESSO A ESSA ROTINA.",'Atenção!',"Filiais Habilitadas para Gestão de Carteira [ZP1-IT_MOMS66FI]: "+_cFilAcesso,3) 
      lRet:=.F.
   EndIf
EndIf

If lRet .And. !_lEfetivar2
   U_ITMsg("Houve Alterações, clique em Reprocessar antes de Efetivar / Gravar",'Atenção!',"",3)
   lRet:=.F.
EndIf

Return lRet


/*
===============================================================================================================================
Programa----------: MOMS66Motivo()
Autor-------------: Alex Wallauer
Data da Criacao---: 23/02/2023
Descrição---------: Motivo do corte
Parametros--------: NENHUM
Retorno-----------: .T. / .F. 
===============================================================================================================================
*/
Static Function MOMS66Motivo()

Local _lRet   := .F. , _oDlg2
Local _amotivs:= {}
Local nLinha  := 10
Local _nCol	  := 15
Local _cQuery := " SELECT "
_cQuery += " DISTINCT X5_CHAVE CHAVE,X5_DESCRI DESCRI "
_cQuery += " FROM "+ RetSqlName("SX5") +" X5 "
_cQuery += " WHERE "
_cQuery += "     D_E_L_E_T_ = ' ' "
_cQuery += " AND X5_TABELA  = 'Z1' AND TRIM(X5_CHAVE) <> '98' AND TRIM(X5_CHAVE) <> '99' "
_cQuery += " ORDER BY X5_CHAVE "
If Select("TMPCF") > 0 
    ("TMPCF")->( DBCloseArea() )
EndIf

DBUseArea( .T. , "TOPCONN" , TCGenQry( ,, _cQuery ) , 'TMPCF' , .F. , .T. )


While TMPCF->( !Eof() )
                               
    aAdd( _amotivs , AllTrim( TMPCF->CHAVE ) + " - " + AllTrim( TMPCF->DESCRI ) )

    TMPCF->( DBSkip() )
EndDo

("TMPCF")->( DBCloseArea() )

Public _cMotivs:= _AMOTIVS[1]

DEFINE MSDIALOG _oDlg2 TITLE ("Corte por exclusão de PVs") From 0,0 To 325, 650 OF oMainWnd PIXEL
                                                                       
    @ nLinha,_nCol Say "Selecione o motivo para corte:"
    nLinha+=12

    _omotiv := TComboBox():New(nLinha,_nCol,{|u|If(PCount()>0,_cMotivs:=u,_cMotivs)}, _amotivs,250,20,_oDlg2,,,,,,.T.,,,,,,,,,'') //40

    nLinha+=38

    @ nLinha,_nCol    Button "OK"      SIZE 41,15 ACTION ( _oDlg2:End(),_lRet := .T. ) Pixel 
    @ nLinha,_nCol+57 Button "Cancela" SIZE 41,15 ACTION ( _oDlg2:End(),_lRet := .F. ) Pixel 

ACTIVATE MSDIALOG _oDlg2 

Return _lRet

/*
===============================================================================================================================
Programa----------: MOMS66DET()
Autor-------------: Julio de Paula Paz
Data da Criacao---: 09/08/2023
Descrição---------: GERA O RELATÓRIO DETALHANDO OS DADOS POR ITENS.
Parametros--------: oProc = Objeto de mensagens / _aTelaPedidos = Dados dos Pedidos de Vendas 
Retorno-----------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66DET(oProc,_aTelaPedidos)

Local _nI, _nX 
Local _aSldItens := {}
Local _aItemSC6
Local _cRegional 
Local _aItens 
Local _cTipoVeic, _cTipoCarga
Local _cCol1, _cCol2, _cCol3
Local _aDadosRel := {}

_nTotDados:=Len(_aTelaPedidos)

If _nTotDados = 0 .Or. ValType(_aTelaPedidos[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return .F.
EndIf
_cTotGeral:=AllTrim(Str(_nTotDados))
   
If ! U_ITMsg("Confirma Emissão do Detalhamento da Listagem de Pedidos Pendentes por Itens ?",'Atenção!',"Serão processado "+_cTotGeral+" pedido(s) e seus itens.",3,2,2)
   Break 
EndIf 

DAI->(DBSetOrder(4)) // DAI_FILIAL+DAI_PEDIDO+DAI_COD+DAI_SEQCAR
DAK->(DBSetOrder(1)) // DAK_FILIAL+DAK_COD+DAK_SEQCAR
DA3->(DBSetOrder(1)) // DA3_FILIAL+DA3_COD                                                                                                                                              
SA1->(DBSetOrder(1))                         
nMarcados   :=0
nDesmarcados:=0

For _nI := 1 To _nTotDados

       oProc:cCaption:="Lendo Pedidos Marcados: "+StrZero(nMarcados,7)+" - Desmarcados: "+StrZero(nDesmarcados,7)
       ProcessMessages()
       If _aTelaPedidos[_nI,nPosOK2] = "LBOK"
          nMarcados++
       ElseIf _aTelaPedidos[_nI,nPosOK2] = "LBNO"
          nDesmarcados++
       EndIf
       If MV_PAR02 = 1 //MARCADOS
          If _aTelaPedidos[_nI,nPosOK2] = "LBNO"
             Loop
          EndIf
       ElseIf MV_PAR02 = 2//DESMARCADOS
          If _aTelaPedidos[_nI,nPosOK2] = "LBOK"
             Loop
          EndIf
       EndIf

       _aItemSC6  := _aTelaPedidos[_nI,_nPosRecnos] // Possui os recnos dos itens dos pedidos de vendas. 
       SC5->(DBGoTo(_aItemSC6[1])) // Posiciona na capa do pedido de vendas.
       // Se tiver carga, busca o tipo de veiculo.
       _cTipoVeic := " "
       If DAI->(MsSeek(SC5->C5_FILIAL+SC5->C5_NUM))
          DAK->(MsSeek(DAI->DAI_FILIAL+DAI->DAI_COD)) 
          If ! Empty(DAK->DAK_CAMINH)
             If DA3->(MsSeek(xFilial("DA3") + DAK->DAK_CAMINH)) 
                If DA3->DA3_I_TPVC == "1" 
                   _cTipoVeic := "CARRETA"
                ElseIf DA3->DA3_I_TPVC == "2" 
                   _cTipoVeic := "CAMINHAO"
                ElseIf DA3->DA3_I_TPVC == "3" 
                   _cTipoVeic := "BI-TREM"
                ElseIf DA3->DA3_I_TPVC == "4" 
                   _cTipoVeic := "UTILITARIO"
                ElseIf DA3->DA3_I_TPVC == "5" 
                   _cTipoVeic := "RODOTREM"
                EndIf 
             EndIf 
          EndIf 
       EndIf 

       // _cTipoCarga
       _cTipoCarga := "Batida"
       If SC5->C5_I_TIPCA == "1"
          _cTipoCarga := "Paletizada"
       ElseIf !SC5->C5_I_TIPCA $ "1/2"
         If SA1->(DBSeek(xFilial("SA1")+SC5->C5_CLIENTE+SC5->C5_LOJACLI))
            If Len(AllTrim(SA1->A1_I_CCHEP)) == 10
                _cTipoCarga :="Paletizada"//-Paletizada"//PALETE CHEP
            Else
                _cTipoCarga:="Batida"//-Batida"    //ESTIVADA
            EndIf   
         EndIf
         If SC5->C5_I_OPER == _cOper50 .Or. SC5->C5_I_OPER == _cOper51 //PEDIDO DE PALLET DEVE SER ENVIADO COMO ESTIVADO
            _cTipoCarga :="Batida"//-Batida"
         EndIf
      EndIf

       _cRegional := U_ROMS002R(SC5->C5_VEND2, SC5->C5_VEND3) // (Coordenador , Gerente ) // Retorna a Regional do Pedido de Vendas
    
       _aSldItens := MOMS66SLDI(_aItemSC6[2]) // Retorna os saldos dos itens dos pedidos de vendas.

       For _nX := 1 To Len(_aSldItens)
           
           SC6->(DBGoTo(_aSldItens[_nX,13]))  
           If SC6->(Deleted())
              Loop
           EndIf

           _cCol1 := "NAO"
           _cCol2 := "NAO"
           _cCol3 := "NAO"

           If Upper(AllTrim(_aTelaPedidos[_nI,nPosCar])) == "ENABLE"
              _cCol1 := "SIM"
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,nPosCar])) == "DISABLE" 
              _cCol1 := "NAO"  
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,nPosCar])) == "BR_AMARELO"
              _cCol1 := "EXCLUIDO"
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,nPosCar])) == "BR_BRANCO"
              _cCol1 := "AGENDAMENTO FUTURO"
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,nPosCar])) $ "BR_PRETO/BR_CINZA"
              _cCol1 := "REAGENDAR"
           EndIf 

           If Upper(AllTrim(_aTelaPedidos[_nI,_nPosEst])) == "ENABLE"
              _cCol2 := "SIM"
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,_nPosEst])) == "DISABLE" 
              _cCol2 := "NAO"  
           EndIf 

           If Upper(AllTrim(_aTelaPedidos[_nI, _nPosCap])) == "ENABLE"
              _cCol3 := "SIM"
           ElseIf Upper(AllTrim(_aTelaPedidos[_nI,_nPosCap])) == "DISABLE" 
              _cCol3 := "NAO"  
           EndIf 

           _aItens := {_cCol1,;                         // "Carregar"          ,"PO_OK"        // 01
                       _cCol2,;                         // "Estoque"           ,"ESTOQUE"      // 02 
                       _cCol3,;                         // "Capacidade"        ,"CAPACIDA"     // 03 _aTelaPedidos[_nI, 6],;  // "Com. Alt"          ,"PO_ORDEMC"     // 4 
                       _aTelaPedidos[_nI,_nPosOrdem ],; // "Com."              ,"PO_ORDEMA"    // 04 
                       _aTelaPedidos[_nI,_nPosPed   ],; // "Pedido"            ,"PEDIDO"       // 05    
                       _aTelaPedidos[_nI,_nPosEms   ],; // "Dt Emissao"        ,"C5_EMISSAO"   // 06 
                       _aTelaPedidos[_nI,_nPosAtraso],; // "Dias"              ,"DIAS_ATRASO"  // 07 
                       _aTelaPedidos[_nI,_nPosEnt   ],; // "Dt Entrega"        ,"C5_I_DTENT"   // 08 
                       _aTelaPedidos[_nI,_nPosNes   ],; // "Dt Necessidade"    ,"DT_NECESSI"   // 09 
                       _aTelaPedidos[_nI,_nPosTpA   ],; // "Tp Agend "         ,"TIPO_AGEND"   // 10 
                       _aTelaPedidos[_nI,_nPosTotPed],; // "Total Pedido"      ,"TOT_PEDIDO"   // 11 
                       _aTelaPedidos[_nI,_nPosPesBru],; // "Peso Bruto"        ,"C5_I_PESBR"   // 12 
                       _aTelaPedidos[_nI,_nPosPesEst],; // "Peso sem Estoque"  ,"PES_S_ESTO"   // 13 
                       _aTelaPedidos[_nI,_nPosPalete],; // "Qtde Palete"       ,"QTDE_PALETE"  // 14 
                       _aTelaPedidos[_nI,_nPosCli   ],; // "Cliente"           ,"C5_CLIENTE"   // 15 
                       _aTelaPedidos[_nI,_nPosVend  ],; // "Vendedor"          ,"C5_VEND1"     // 16   
                       _aTelaPedidos[_nI,_nPosCoor  ],; // "Coordenador"       ,"C5_VEND2"     // 17   
                       _aTelaPedidos[_nI,_nPosGer   ],; // "Gerente"           ,"C5_VEND3"     // 18   
                       _aTelaPedidos[_nI,_nPosMun   ],; // "Mucnicipio"        ,"C5_I_MUN"     // 19   
                       _aTelaPedidos[_nI,_nPosUF    ],; // "UF"                ,"C5_I_EST"     // 20 
                       _aTelaPedidos[_nI,_nPosTpO   ],; // "Tp Operacao"       ,"C5_I_OPER"    // 21 
                       _aTelaPedidos[_nI,_nPosTpF   ],; // "Tp Frete"          ,"C5_TPFRETE"   // 22 
                       _aTelaPedidos[_nI,_nPosPedVin],; // "Ped. Vinculado"    ,"C5_I_PEVIN"   // 23 
                       _aTelaPedidos[_nI,_nPosObs   ],; // "Observacao"        ,"OBSERVAC"     // 24   
                       _aTelaPedidos[_nI,_nPosReg   ],; // "Qtd Reagend."      ,"C5_I_QTDA"    // 25  
                       _aTelaPedidos[_nI,_nPosDias  ],; // "T.T."              ,"DIAS"         // 26  
                       _cTipoCarga,;                    // "Tipo de Carga"     ,"C5_I_TIPCA"   // 27
                       _aTelaPedidos[_nI,_nPosChave ],; // "Controle"          ,"CONTROLE"     // 28 
                       _cTipoVeic,;                     // Tipo de Veiculo                     // 29
                       _cRegional,;                     // Regional                            // 30
                       SC6->C6_PRODUTO,;                // Produto                             // 31
                       SC6->C6_DESCRI,;                 // Descrição                           // 32  
                       SC6->C6_UNSVEN,;                 // Quantidade Segunda unid. med.       // 33
                       SC6->C6_SEGUM,;                  // Segunda Unid. Medida                // 34
                       SC6->C6_QTDVEN,;                 // Quantidade                          // 35
                       SC6->C6_UM,;                     // Unidade de Medida                   // 36
                       SC6->C6_PRCVEN,;                 // Preço Unitário                      // 37
                       SC6->C6_VALOR,;                  // Valor Total                         // 38
                       _aSldItens[_nX,3],;              // Saldo Atual                         // 39
                       _aSldItens[_nX,4],;              // Qtd. Reserva                        // 40 
                       _aSldItens[_nX,5],;              // Qtd. Empenhada                      // 41
                       _aSldItens[_nX,6],;              // Saldo Disponível                    // 42
                       _aSldItens[_nX,7]}               // Armazem                             // 43

           aAdd(_aDadosRel, _aItens)
                              
       Next 
Next  

   aDadosXML:=ACLONE(_aDadosRel)

   _cTitulo := _cTitExcel+" / "+_cFilPrc+ " - " + AllTrim(FWFilialName(cEmpAnt,_cFilPrc,1))//'Lista de Pedidos Pendentes Detalhados por Itens'
   
   _aCabec := {"Carregar?",;                          // 01 Legenda
               "Tem Estoque?",;                       // 02 Legenda
               "Tem Capacidade?",;                    // 03 Legenda 
               "Posicao",;                            // 04 
               "Pedido",;                             // 05    
               "Dt Emissao",;                         // 06 
               "Dias",;                               // 07 
               "Dt Entrega",;                         // 08 
               "Dt Necessidade",;                     // 09 
               "Tp Agend ",;                          // 10 
               "Total Pedido",;                       // 11 
               "Peso Bruto",;                         // 12 
               "Peso sem Estoque",;                   // 13 
               "Qtde Palete",;                        // 14 
               "Cliente",;                            // 15 
               "Vendedor",;                           // 16   
               "Coordenador",;                        // 17   
               "Gerente",;                            // 18   
               "Mucnicipio",;                         // 19   
               "UF",;                                 // 20 
               "Tp Operacao",;                        // 21 
               "Tp Frete",;                           // 22 
               "Ped. Vinculado",;                     // 23 
               "Observacao",;                         // 24   
               "Qtd Reagend.",;                       // 25  
               "T.T.",;                               // 26  
               "Tipo de Carga",;                      // 27 
               "Controle",;                           // 28 
               "Tipo de Veiculo",;                    // 29
               "Regional",;                           // 30
               "Produto",;                            // 31 
               "Descrição",;                          // 32  
               "Quantidade Segunda unid. med.",;      // 33
               "Segunda Unid. Medida",;               // 34
               "Quantidade",;                         // 35
               "Unidade de Medida",;                  // 36
               "Preço Unitário",;                     // 37
               "Valor Total",;                        // 38
               "Saldo Atual",;                        // 39 
               "Qtd. Reserva",;                       // 40 
               "Qtd. Empenhada",;                     // 41
               "Saldo Disponível",;                   // 42
               "Armazem"}                             // 43

   cPictQ:=AVSX3('C6_QTDVEN',6)
   cPictP:=AVSX3('C6_VALOR' ,6)
   cPictN:="@E 9,999"
   For _nX := 1 TO Len(_aDadosRel)
       _aDadosRel[_nX,12] := TRANS( (_aDadosRel[_nX,12]) , cPictQ )
       _aDadosRel[_nX,13] := TRANS( (_aDadosRel[_nX,13]) , cPictQ )
       _aDadosRel[_nX,14] := TRANS( (_aDadosRel[_nX,14]) , cPictQ )
       _aDadosRel[_nX,33] := TRANS( (_aDadosRel[_nX,33]) , cPictQ )
       _aDadosRel[_nX,35] := TRANS( (_aDadosRel[_nX,35]) , cPictQ )
       _aDadosRel[_nX,39] := TRANS( (_aDadosRel[_nX,39]) , cPictQ )
       _aDadosRel[_nX,40] := TRANS( (_aDadosRel[_nX,40]) , cPictQ )
       _aDadosRel[_nX,41] := TRANS( (_aDadosRel[_nX,41]) , cPictQ )
       _aDadosRel[_nX,42] := TRANS( (_aDadosRel[_nX,42]) , cPictQ )

       _aDadosRel[_nX,04] := TRANS( (_aDadosRel[_nX,04]) , cPictN )
       _aDadosRel[_nX,07] := TRANS( (_aDadosRel[_nX,07]) , cPictN )
       _aDadosRel[_nX,25] := TRANS( (_aDadosRel[_nX,25]) , cPictN )
       _aDadosRel[_nX,26] := TRANS( (_aDadosRel[_nX,26]) , cPictN )       
       
       _aDadosRel[_nX,11] := "R$  "+AllTrim(TRANS( (_aDadosRel[_nX,11]) , cPictP ))
       _aDadosRel[_nX,37] := "R$  "+AllTrim(TRANS( (_aDadosRel[_nX,37]) , cPictP ))
       _aDadosRel[_nX,38] := "R$  "+AllTrim(TRANS( (_aDadosRel[_nX,38]) , cPictP ))
   Next
//   ITListBox( _cTitAux , _aHeader , _aCols    , _lMaxSiz , _nTipo , _cMsgTop , _lSelUnc , _aSizes , _nCampo , bOk , bCancel, _abuttons, _aCab , bDblClk , _aColXML , bCondMarca,_bLegenda,_lHasOk,_bHeadClk,_aSX1)
   U_ITListBox(_cTitulo  , _aCabec  , _aDadosRel, .T.    , 1    , /*_cMsgTop*/ ,          , /*aSize*/  ,         ,     ,        ,          ,       ,      ,aDadosXML ,           ,         ,       ,         )

Return 

/*
===============================================================================================================================
Programa--------: MOMS66SLDI
Autor-----------: Julio de Paula Paz
Data da Criacao-: 09/08/2023
Descrição-------: Rotina para retornar os saldos dos itens de pedidos de vendas. Versão simplificada da função MOMS66B2.
Parametros------: _aItemSC6 = Array com os itens do pedido de vendas.
Retorno---------: _aRet = Array com os saldos e dados dos itens dos pedidos de vendas.
===============================================================================================================================
*/
Static Function MOMS66SLDI(_aItemSC6)

Local _nI 
Local _lSomaPTer:= .F.
Local _nSaldoDisp, _aRet  

SB2->(DBSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL
_aRet := {}

For _nI := 1 To Len(_aItemSC6)
        
       SC6->(DBGoTo(_aItemSC6[_nI,1]))
       If SC6->(Deleted())
          Loop
       EndIf

       If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL)) //.And. (aScan(_aRet, {|x| x[1] == SB2->B2_FILIAL .And. x[2] == SB2->B2_COD .And. x[7] == SB2->B2_LOCAL})) = 0
        
          _lSomaPTer := (SC6->C6_FILIAL $ _cFilTer .And. SC6->C6_LOCAL $ _cLocTer)

          _nSaldoDisp:=SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)
               //_nSaldoDisp:=If( _nSaldoDisp < 0 , 0 , _nSaldoDisp ) //ZEREI O SALDO NEGATIVO PARA NÃO DAR ERRO NOS CALDULOS DE PESO			   

          aAdd(_aRet, {SB2->B2_FILIAL ,;   //01 - FILIAL
                       SB2->B2_COD    ,;   //02 - PRODUTO
                       SB2->B2_QATU   ,;   //03 - 1UM
                       SB2->B2_RESERVA,;   //04 - 1UM
                       SB2->B2_QEMP   ,;   //05 - 1UM
                       _nSaldoDisp    ,;   //06 - DISPONIVEL FINAL 1UM
                       SB2->B2_LOCAL  ,;   //07 - ARMAZEM
                       If(_lSomaPTer,SB2->B2_QNPT,0),;//08 -  1UM
                       0              ,;   //09 - Quantidade Carteira na 2ª UM (SOMTORIA BOLINHA VERDE)
                       0              ,;   //10 - Saldo na 2ª UM (DISPONIVEL - BOLINHA VERDE) CALCULADO
                       SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0),;//11-DISPONIVEL INICIAL 1UM
                       0              ,;   //12 - SOMATORIA DAS RESERVAS DOS GERENTES 1UM
                       SC6->(Recno())})    //13 - Recno item de Pedido de Vendas (Tabela SC6) 

        EndIf
    
Next 

Return _aRet 

/*
===============================================================================================================================
Programa--------: ITRegiaoBR(cEstado)
Autor-----------: Alex Wallauer
Data da Criacao-: 12/03/2024
Descrição-------: Rotina para retornar as Regioes do Brasil
Parametros------: Estado (UF) , _cMesoReg
Retorno---------: Regiao do Brasil
===============================================================================================================================
*/
User Function ITRegiaoBR(cEstado,_cMesoReg)

Local cRegiao:= "N/A"
If cEstado $ "SP|RJ|MG|ES"
    cRegiao := "Regiao Sudeste"
ElseIf cEstado $ "SC|RS|PR"
    cRegiao := "Regiao Sul"
ElseIf cEstado $ "MS|MT|TO|GO|DF"
    cRegiao := "Regiao Centro Oeste"
ElseIf cEstado $ "AC|AM|AP|MA|PA|RO|RR"
    cRegiao := "Regiao Norte"
ElseIf cEstado $ "AL|BA|CE|PB|PE|PI|RN|SE"
    cRegiao := "Regiao Nordeste"
ElseIf cEstado $ "EX"
    cRegiao := "Exterior"
EndIf

If aScan(aFolderMeso,{|M| M[1] = cRegiao .And. M[2] = _cMesoReg } ) = 0
   aAdd(aFolderMeso,{cRegiao,_cMesoReg})
EndIf

Return cRegiao


/*
===============================================================================================================================
Programa--------: MOMS66PVinc
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2024
Descrição-------: Analiza os pedidos vinculados e marca a ordem de consumo do estoque
Parametros------: _aPedidos
Retorno---------: _aPedidos
===============================================================================================================================
*/
Static Function MOMS66PVinc(_aPedidos)

Local P 

_aPedidos:=aSort(_aPedidos,,,{|X,Y| X[_nPosChave] < Y[_nPosChave] })//ORDENA PELA CHAVE DE PRIORIDADE

For P := 1 TO Len(_aPedidos) //ANALISE DOS PEDIDOS VINCULADOS 
    If Empty(_aPedidos[P,_nPosPedVin]) //NÃO TEM VINCULADO Loop
       Loop
    EndIf	   
    If (_nPosVin:=aScan(_aPedidos,{|aPed| aPed[_nPosPed] == _aPedidos[P,_nPosPedVin] } )) > 0 //ACHOU PEDIDO VINCULADO NA MESMA ABA
       _cPedVinc:=_cFilPrc+_aPedidos[P,_nPosPedVin] 
       If !SC5->(DBSeek( _cPedVinc))
         _aPedidos[P,_nPosPedVin]:="Nao achou (SC5): "+_cPedVinc
         Loop
       EndIf
       If SC5->C5_I_OPER == _cOper50 .Or. SC5->C5_I_OPER == _cOper51 //SE PEDIDO DE PALETE VINCULADO IGNORA
          _aPedidos[_nPosVin,_nPosPedVin]:="Palete: "+_aPedidos[_nPosVin,_nPosPedVin]
          Loop
       EndIf
       _aPedidos[P,_nPosChave]:=_aPedidos[_nPosVin,_nPosChave]//IGUALA A CHAVE PARA FICAREM JUNTAS
       If _aPedidos[_nPosVin,nPosCar] = "BR_PRETO" .Or. _aPedidos[_nPosVin,nPosCar] = "BR_BRANCO"
          If _aPedidos[P,nPosCar ] $ "ENABLE/DISABLE"
             _aPedidos[P,nPosCar ]:="BR_CINZA"//_aPedidos[_nPosVin,nPosCar]
          EndIf
          If Empty(_aPedidos[P,_nPosObs])
              _aPedidos[P,_nPosObs]:="O pedido "+_aPedidos[P,_nPosPedVin]+" vinculado a esse pedido "+_aPedidos[P,_nPosPed]+" esta fora do criterio de pendencias (Legenda)"
          EndIf
       EndIf
    Else
        If (_nPos:=aScan(aPedVin,{|aPed| aPed[1] == _aPedidos[P,_nPosPedVin] } )) > 0//SE ACHOU NA LISTA GERAL DE VINCULADOS
           _cPedVinc:=_cFilPrc+_aPedidos[P,_nPosPedVin] 
            If !SC5->(DBSeek( _cPedVinc))
              _aPedidos[P,_nPosPedVin]:="Nao achou (SC5): "+_cPedVinc
              Loop
           EndIf 
           If SC5->C5_I_OPER == _cOper50 .Or. SC5->C5_I_OPER == _cOper51 //SE PEDIDO DE PALETE VINCULADO IGNORA
              _aPedidos[_nPosVin,_nPosPedVin]:="Palete: "+_aPedidos[_nPosVin,_nPosPedVin]
              Loop
           EndIf
           _cObs:="O pedido "+_aPedidos[P,_nPosPedVin]+" vinculado a esse pedido "+_aPedidos[P,_nPosPed]+" esta na pasta: "+aPedVin[_nPos,3]
        Else//SE NAÕ ACHOU NA LISTA GERAL DE VINCULADOS
           _cObs:="O pedido "+_aPedidos[P,_nPosPedVin]+" vinculado a esse pedido "+_aPedidos[P,_nPosPed]+" esta fora do criterio de pendencias. (Filtro)"
        EndIf
        If _aPedidos[P,nPosCar ] $ "ENABLE/DISABLE"
           _aPedidos[P,nPosCar ]:="BR_CINZA"//"BR_PRETO"
        EndIf
        _aPedidos[P,_nPosObs]:=_cObs
    EndIf
Next
   
_aPedidos:=aSort(_aPedidos,,,{|X,Y| X[_nPosChave] < Y[_nPosChave] })//REORDENA PELA CHAVE DE PRIORIDADE

//MARCA A ORDEM DE CONSUMO DO ESTOQUE
For P := 1 TO Len(_aPedidos)
   _aPedidos[P,_nPosOrdem]:=P
Next
//MARCA A ORDEM DE CONSUMO DO ESTOQUE

Return _aPedidos

/*
===============================================================================================================================
Programa--------: MOMS66Ord
Autor-----------: Alex Wallauer
Data da Criacao-: 14/03/2024
Descrição-------: Processa o pedido para retornar a prioridade
Parametros------: _cClassEnt
Retorno---------: _cChave
===============================================================================================================================
*/
Static Function MOMS66Ord(_cClassEnt)

Local _cChave:= "9999"

//Chave Prioridade Comercial + Prioridade Tipo de Agendamento + Qtd de Reagendamento + Data de Emissao + Pedido 			
If SC5->C5_I_OPER = "20" .And. SC5->C5_I_TRCNF <> "S" 
   _cChave:="2599"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM                           // PRIORIDADE: 02
ElseIf SC5->C5_TPFRETE = "F"                                                    
   _cChave:="8599"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM                           // PRIORIDADE: 05
ElseIf SC5->C5_I_AGEND = "M"
   _cChave:="10"+StrZero(99-SC5->C5_I_QTDA,2)+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM// PRIORIDADE: 01 *
ElseIf SC5->C5_I_AGEND = "A"
   _cChave:="35"+StrZero(99-SC5->C5_I_QTDA,2)+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM// PRIORIDADE: 03
ElseIf SC5->C5_I_AGEND $ "I/O"
   _cChave:="3599"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM                           // PRIORIDADE: 04
Else
   _cChave:="9099"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM                           // PRIORIDADE: 06
EndIf  

_dDataCalculada:=SC5->C5_I_DTENT
_cObs:=""
_nDias:=0

If _cClassEnt == "1-TOP 1 NACIONAL"
   _cChave:="0"+_cChave// PRIORIDADE: 01 * 
Else
   _cChave:="1"+_cChave// PRIORIDADE: 02
EndIf
_lAchouZG5:=.F.
_cRegra:=""

If SC5->C5_I_AGEND $ "M,A" .And. SC5->C5_TPFRETE <> "F"  .And. SC5->C5_I_OPER <> "20" 

   aHeader:={}//Usa na funcao U_OMSVLDEN T()
   aCols  :={}//Usa na funcao U_OMSVLDEN T()
   _nDias:=(U_OMSVLDENT(SC5->C5_I_DTENT,SC5->C5_CLIENTE,SC5->C5_LOJACLI,SC5->C5_I_FILFT,SC5->C5_NUM,1,.F.,SC5->C5_FILIAL,SC5->C5_I_OPER,SC5->C5_I_TPVEN,@_lAchouZG5,@_cRegra,SC5->C5_I_LOCEM))

   If SC5->C5_I_TPVEN == "F"     // Carga Fechada 
      _dDataCalculada:=SC5->C5_I_DTENT-_nDias 
      _dDataCalculada:=DataValida( _dDataCalculada, .F. )  // VOLTA DIAS CORRIDOS 
   ElseIf SC5->C5_I_TPVEN == "V" // Carga Fracionada (Varejo)
      _nI:= 0
      While _nI < _nDias
         _dDataCalculada := (_dDataCalculada - 1 )         // VOLTA DIAS UTEIS
         If _dDataCalculada =  DataValida( _dDataCalculada, .F. )
            _nI++
         EndIf 	
      EndDo
   EndIf
   If _dDataCalculada > _dHoje 
      If (MV_PAR07 = 2) //SE NÃO MOSTRA A CARTEIRA TODA = NÃO 
         _cChave:="Loop"
      Else
         _cObs:="D-Data de necessidade ("+DToC(_dDataCalculada)+") MAIOR que HOJE."//"BR_BRANCO"
         _cChave:="9699"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM       
      EndIf
   ElseIf _dDataCalculada < _dHoje
      _cObs:="A-Data de necessidade ("+DToC(_dDataCalculada)+") MENOR que HOJE. Pedido será alterado para Reagendar"//"BR_PRETO"
      _cChave:="9599"+DToS(SC5->C5_EMISSAO)+SC5->C5_NUM
   EndIf
    
EndIf

Return _cChave

/*
===============================================================================================================================
Programa----------: MOMS66Obj
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: Retorna o Browse da pasta ativa
Parametros--------: lPasta: devolve nome e numero da pasta se .T. senão o objeto 
Retorno-----------: oMsMGet ativo
===============================================================================================================================*/
Static Function MOMS66Obj(lPasta)

Local nPos
Local cTitPasta:=""
Local nPasta:=(oTFolder01:nOption)
Default lPasta:=.F.

lRegioes:=.F.
cPastaR:=""

If Len(oTFolder01:aPrompts) > 0 .And. nPasta > 0
   cTitPasta:=oTFolder01:aPrompts[nPasta]
   cPastaR:=cTitPasta//Pasta 1 e 2 e 3
EndIf

If Len(aFoders1) > 3 .And. cTitPasta = aFoders1[4]
   nPasta:=oPastaRegs:nOption
   If Len(oPastaRegs:aPrompts) > 0 .And. nPasta > 0
      cTitPasta:=oPastaRegs:aPrompts[nPasta]
      cPastaR:=cTitPasta//Pastas das Regioes
      lRegioes:=.T.
   EndIf
   If cTitPasta = aFolderRGBR[1]
      nPasta:=oPastMeso1:nOption
      If Len(oPastMeso1:aPrompts) > 0 .And. nPasta > 0
         cTitPasta:=oPastMeso1:aPrompts[nPasta]
      EndIf
   ElseIf cTitPasta = aFolderRGBR[2]
      nPasta:=oPastMeso2:nOption
      If Len(oPastMeso2:aPrompts) > 0 .And. nPasta > 0
         cTitPasta:=oPastMeso2:aPrompts[nPasta]
      EndIf
   ElseIf cTitPasta = aFolderRGBR[3]
      nPasta:=oPastMeso3:nOption
      If Len(oPastMeso3:aPrompts) > 0 .And. nPasta > 0
         cTitPasta:=oPastMeso3:aPrompts[nPasta]
      EndIf
   ElseIf cTitPasta = aFolderRGBR[4]
      nPasta:=oPastMeso4:nOption
      If Len(oPastMeso4:aPrompts) > 0 .And. nPasta > 0
         cTitPasta:=oPastMeso4:aPrompts[nPasta]
      EndIf
   ElseIf cTitPasta = aFolderRGBR[5]
      nPasta:=oPastMeso5:nOption
      If Len(oPastMeso5:aPrompts) > 0 .And. nPasta > 0
         cTitPasta:=oPastMeso5:aPrompts[nPasta]
      EndIf
   EndIf
EndIf

If lPasta
   If ValType(cTitPasta) <> "C"
      cTitPasta:=""
   ElseIf lRegioes  
      cTitPasta:="Meso: "+cTitPasta
   Else
      cTitPasta:=": "+cTitPasta
   EndIf
   Return {cTitPasta,If(nPasta>0,nPasta,1)} // SAIDA 1
EndIf

oMsMGet:=NIL
If (nPos:=aScan(aBrowses, {|B| B[1] == cTitPasta } )) > 0
   
   oMsMGet:=aBrowses[nPos,2]

Else
   Return  // SAIDA 2
EndIf

Return oMsMGet // SAIDA 3

/*
===============================================================================================================================
Programa----------: MOMS66Atu
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: Atualiza todos os valores totais da tela 
Parametros--------: _cOrigem: dá onde chamou ,_nX,_aTelaPedidos
Retorno-----------: .T. ou .F.
===============================================================================================================================*/
Static Function MOMS66Atu(_cOrigem,_nX,_aTelaPedidos)

Local nRNaoGerFin:= nVlrPGerFin := 0

cOrigemDebug    :=_cOrigem//VARIAVEL Private PARA APARECER NO ERROR.LOG 
lRegioes        :=.F.//ALTERA DENTRO DA MOMS66Obj ()
cPastaR         :="" //ALTERA DENTRO DA MOMS66Obj ()

If _cOrigem = "MARCA" // MARCA E DESMARCA 

   If Len(_aTelaPedidos) = 0 .Or. ValType(_aTelaPedidos[_nX][_nPosRecnos]) <> "A"//LINHA EM BRANCO
      Return .F.
   EndIf

// ATUALIZA OS TOTAIS DA PARTE DE CIMA
   _lPalitizada  :=_aTelaPedidos[_nX][_nPosTPCA] = "1"
   _nPedTotPalete:=_aTelaPedidos[_nX][_nPosPalete]//Qtde de Paletes do Pedido 
    
   SC5->(DBGoTo(_aTelaPedidos[_nX][_nPosRecnos][1]))

    SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
    If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = 'S' 
       nVlrPGerFin:=_aTelaPedidos[_nX][_nPosTotPed]
       nRNaoGerFin:=0
    Else
       nVlrPGerFin:=0
       nRNaoGerFin:=SC5->C5_I_PESBR
    EndIf

    If _aTelaPedidos[_nX][nPosOK2] = "LBOK" //COLUNA REAL
       _nTotGerFin   +=nVlrPGerFin
       _nTotNaoGerFin+=nRNaoGerFin
    ElseIf _aTelaPedidos[_nX][nPosOK2] = "LBNO" //COLUNA REAL
       _nTotGerFin   -=nVlrPGerFin
       _nTotNaoGerFin-=nRNaoGerFin
    EndIf
  
    oSAYPesLib:Refresh()   
    oSAYPalLib:Refresh()   
    oSAYVlGer:Refresh() 
    oSAYPesNGer:Refresh()     
//ATUALIZA OS TOTAIS DA PARTE DE CIMA

EndIf

// TODAS AS PASTAS QUANDO TROCA DE PASTA
oSAYNPastA:Refresh()

//CASO A PASTA 1 E 2 ESTEJA ZERADA 
_nRMesoPesoLib  :=0
_nVMesoPesoLib  :=0
_nRMesoPalsLib  :=0
_nVMesoPalsLib  :=0
_nRMesoValor    :=0
_nVMesoValor    :=0
_nRMesoNaoGerFin:=0
_nMesoPonFat    :=0
nMesoPonPeso    :=0
_nVCMesoPalsLib :=0
_nVCMesoPesoLib :=0
_cRQtdeCarrega  :=" "
oSAYValCar:Refresh()
oSAYRPeso:Refresh()
oSAYVPeso:Refresh()
oSAYRPale:Refresh()
oSAYVPale:Refresh()
oSAYRVGerF:Refresh()
oSAYVVGerF:Refresh()
oSAYRPnGer:Refresh()
oSAYVPnGer:Refresh()
oBotValCar:Hide()
oSAYValCar:Hide()
_nTotPonFat:=_aTotPonFat[1,2]
_nToRPonFat:=0
oSAYToPon:Refresh()
oSAYRTotPon:Refresh()
//CASO A PASTA 1 E 2 ESTEJA ZERADA 

If (oMsMGet:=MOMS66Obj()) = NIL 
   Return .F.
EndIf

If lRegioes//lRegioes: INICIADA DENTRO DA MOMS66Obj ()
   oBotValCar:Show()
   oSAYValCar:Show()
Else
   oBotValCar:Hide()
   oSAYValCar:Hide()
EndIf

If (nPos:=aScan(_aTotPonFat,{|P| P[1] == cPastaR })) > 0 //ALTERA DENTRO DA MOMS66Obj ()
    _nToRPonFat:=_aTotPonFat[nPos,2]
EndIf
oSAYRTotPon:Refresh()

_aTelaPedidos:=oMsMGet:aCols
If Len(_aTelaPedidos) = 0
   Return .F.
EndIf

If ValType(_aTelaPedidos[1][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return .F.
EndIf

If _cOrigem <> "MARCA" .And. _cOrigem <> "INICIO" .And. lClicouMarca
   FWMsgRun( ,{|oProc| MOMS66Atu2(oMsMGet,oProc) },"Reprocessando PASTA...","Aguarde...")  //TODAS AS PASTAS
EndIf

//ATUALIZA O RODAPE DA TELA COM OS TOTAIS DA PASTA

_nRMesoPesoLib  :=0
_nVMesoPesoLib  :=0
_nRMesoPalsLib  :=0
_nVMesoPalsLib  :=0
_nRMesoValor    :=0
_nVMesoValor    :=0
_nRMesoNaoGerFin:=0
_nMesoPonFat    :=0
nMesoPonPeso    :=0
_nVCMesoPalsLib :=0
_nVCMesoPesoLib :=0

For _nX := 1 TO Len(_aTelaPedidos)

    _lPalitizada  :=_aTelaPedidos[_nX][_nPosTPCA] = "1"
    _nPedTotPalete:=_aTelaPedidos[_nX][_nPosPalete]//Qtde de Paletes do Pedido 
    
    SC5->(DBGoTo(_aTelaPedidos[_nX][_nPosRecnos][1]))

    SC6->(DBSeek(SC5->C5_FILIAL+SC5->C5_NUM))
    If SC5->C5_I_OPER = "42" .Or. Posicione("SF4",1,xFilial("SF4")+SC6->C6_TES,"F4_DUPLIC") = 'S' 
       nVlrPGerFin:=_aTelaPedidos[_nX][_nPosTotPed]
       nRNaoGerFin:=0
    Else
       nVlrPGerFin:= 0
       nRNaoGerFin:=SC5->C5_I_PESBR
    EndIf

    If !_aTelaPedidos[_nX,nPosCar]  $ LEGENDAS_ABCP
       _nMesoPonFat+=nVlrPGerFin
       nMesoPonPeso+=SC5->C5_I_PESBR
    EndIf

     If _aTelaPedidos[_nX][nPosOK] = "LBOK" //COLUNA SUGERIDA 
        _nVMesoValor    +=nVlrPGerFin
        //If _lPalitizada
           _nVMesoPalsLib+=_nPedTotPalete
        //Else
           _nVMesoPesoLib+=SC5->C5_I_PESBR
        //EndIf
     EndIf

     If _aTelaPedidos[_nX][nPosOK2] = "LBOK" //COLUNA REAL
        _nRMesoValor+=nVlrPGerFin
        _nRMesoNaoGerFin+=nRNaoGerFin
           _nRMesoPalsLib+=_nPedTotPalete
           _nRMesoPesoLib+=SC5->C5_I_PESBR

        If !Empty(_aTelaPedidos[_nX][nPosC1])
           Loop
         EndIf
           _nVCMesoPalsLib+=_aTelaPedidos[_nX][_nPosPalete]//Qtde de Paletes do Pedido 
           _nVCMesoPesoLib+=SC5->C5_I_PESBR 
     EndIf

Next

_cRQtdeCarrega:=" "
If _nVCMesoPesoLib > 0 
   _cRQtdeCarrega:="TO "+AllTrim(TRANS( _nVCMesoPesoLib/1000 ,"@E 999,999,999,999.999"))
EndIf
If _nVCMesoPalsLib > 0
   If _nVCMesoPesoLib > 0 
      _cRQtdeCarrega:=_cRQtdeCarrega+" / "+AllTrim(TRANS( _nVCMesoPalsLib ,"@E 999,999.999"))+ " Palete(s)"
   Else
      _cRQtdeCarrega:=AllTrim(TRANS( _nVCMesoPalsLib ,"@E 999,999.999"))+ " Palete(s)"
   EndIf	
EndIf
oSAYValCar:Refresh()

oSAYRPeso:Refresh()
oSAYVPeso:Refresh()
oSAYRPale:Refresh()
oSAYVPale:Refresh()

oSAYRVGerF:Refresh()
oSAYVVGerF:Refresh()
oSAYRPnGer:Refresh()
oSAYVPnGer:Refresh()

//ATUALIZA O RODAPE DA TELA COM OS TOTAIS DA PASTA

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66Val
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: Atualiza o ESTOQUE
Parametros--------: _nX,_aTelaPedidos,_cRet
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MOMS66Val(_nX,_aTelaPedidos,_cRet)

Local _nY 

If Len(_aTelaPedidos) = 0
   Return .F.
EndIf
If ValType(_aTelaPedidos[_nX][_nPosRecnos]) <> "A"//LINHA EM BRANCO
   Return .F.
EndIf

_aSC6_do_PV:=ACLONE(_aTelaPedidos[_nX][_nPosRecnos])
SC5->(DBGoTo(_aSC6_do_PV[1]))

_cPedAtual:=SC5->C5_FILIAL+SC5->C5_NUM
If !SC5->(DBSeek( _cPedAtual)) //Pedido que não existe mais nessa filial
    _aTelaPedidos[_nX,nPosCar] := "BR_AMARELO"
    _aTelaPedidos[_nX,_nPosObs]:= "Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM+". FAÇA O REPROCESSAMENTO."
    U_ITMsg("Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM,'Atenção!',,1)
    Return .F.
EndIf
    
// Pedidos para ignorar
If _aTelaPedidos[_nX][nPosCar] $ LEGENDAS_ABCP
    Return .F.
EndIf

If !MOMS66Acesso()
   Return .F.
EndIf

// ESTOQUE
_nPesoCapacFil:=_aSC6_do_PV[3]//_nCapacPes
_nPaleCapacFil:=_aSC6_do_PV[5]//_nCapacPal
_lTemEstoque  :=.T.
_cProdSEst    :=""
_cObs         :=""
_aSB2         := MOMS66aSB2(_aSB2,"SALVA")

For _nY := 1 TO Len(_aSC6_do_PV[2]) // Loop NO ITENS DO PEDIDO
        
        SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
        If SC6->(DELETED())
           Loop
        EndIf
    
        //REALIZA A CONSUMO DA SB2 
        If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] = SC6->C6_LOCAL })) > 0 				
            
            //            Disponivel      //- reservas dos gerentes + reserva do gerente do pedidos posicinado
            _nSaldoDisp:=_aSB2[_nPos][06] //- _aSB2[_nPos][12]    //+ _nReservGer

            If _cRet = "LBOK"//REALIZA O CONSUMO DA SB2  *** MARCA ***

                If _nSaldoDisp >= SC6->C6_QTDVEN //.AND. (_nReservGer = 0 .Or. _nReservGer > SC6->C6_QTDVEN) // SE TEM ESTOQUE
                   
                   _aSB2[_nPos][06]-= SC6->C6_QTDVEN // (SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP) // DISPONIVEL
                   
                   _aSC6_do_PV[2][_nY,2]:=.T. //MARCA O ITEM QUE TEM ESTOQUE PARA GRAVAR ZY8 (MOMS66ZY8 ())
    
                    //BOTÃO: "VER / CORTAR Itens Pedido""
                    _nQtdeATend := SC6->C6_QTDVEN
                    _nQtdeFalta := 0
                    _nPesoFalta := 0

                    //CARREGA FATOR DE CONVERSÃO SE EXISTIR
                    _nfator := 1
                    If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
                       If SB1->B1_CONV == 0
                          If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                                _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                          EndIf
                       Else
                          _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
                       EndIf
                    EndIf			    
                    //BOTÃO: "VER / CORTAR Itens Pedido""
                    _aSC6_do_PV[2][_nY,3]:=(_nQtdeATend*_nfator)
                    _aSC6_do_PV[2][_nY,4]:=_nQtdeFalta
                    _aSC6_do_PV[2][_nY,5]:=_nPesoFalta

                Else
                     
                    _lTemEstoque:=.F.
                    _cProdSEst  +=CRLF+AllTrim(SC6->C6_PRODUTO)+"/ Qtde "+AllTrim(TRANS(SC6->C6_QTDVEN,"@E 999,999,999,999.999")) +" > Saldo "+AllTrim(TRANS(_nSaldoDisp,"@E 999,999,999,999.999"))
                
                EndIf
                
            ElseIf _cRet = "LBNO"//ACRESCENTA NO ESTOQUE DE VOLTA *** DESMARCA ***

                _aSB2[_nPos][06]+= SC6->C6_QTDVEN // (SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP) // DISPONIVEL			    

                //BOTÃO: "VER / CORTAR Itens Pedido""
                _aSC6_do_PV[2][_nY,3]:=0//_nQtdeATend
                _aSC6_do_PV[2][_nY,4]:=0//_nQtdeFalta
                _aSC6_do_PV[2][_nY,5]:=0//_nPesoFalta

            EndIf
        Else
            U_ITMsg("Pedido / Produto / Local: "+SC6->C6_NUM+" / "+AllTrim(SC6->C6_PRODUTO)+" / "+SC6->C6_LOCAL+" não encontrado no estoque (_aSB2).",'Atenção!',"Faça o reprocessamento ou/e entre em contato com o TI.",1)
            Return .F.//SAIR SEM FAZER NADA
        EndIf
Next 

// VINCULADOS
//VER SE TEM PEDIDO VINVCULADO TESTA AQUI JUNTO COM O OUTRO PEDIDO
nPosVinc:=0
If (nPosVinc:=aScan(_aTelaPedidos,{|aPed| aPed[_nPosPed] == SC5->C5_I_PEVIN } ) ) > 0 ;//PROCURA O PEDIDO VINCULADO NA _ATELAPEDIDOS
             .And. !_aTelaPedidos[nPosVinc,nPosCar] $ LEGENDAS_ABCP
   
   _aSC6doVinc:=ACLONE(_aTelaPedidos[nPosVinc][_nPosRecnos])
   
   SC5->(DBGoTo(_aSC6doVinc[1]))//PEDIDO VINCULADO
   _cPedAtual:=SC5->C5_FILIAL+SC5->C5_NUM
   If !SC5->(DBSeek( _cPedAtual)) //PEDIDO QUE NÃO EXISTE MAIS NESSA FILIAL
      _aTelaPedidos[nPosVinc,nPosCar] := "BR_AMARELO"
      _aTelaPedidos[nPosVinc,_nPosObs]:= "Pedido não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM+". FAÇA O REPROCESSAMENTO."
      U_ITMsg("Pedido vinculado não existe mais nessa filial: "+SC5->C5_FILIAL+" "+SC5->C5_NUM,'Atenção!',"Faça o reprocessamento ou tente marca novamente esse pedido.",1)
      Return .F.
   EndIf

   For _nY := 1 TO Len(_aSC6doVinc[2]) // Loop NO ITENS DO PEDIDO VINCULADO
        
        SC6->(DBGoTo(_aSC6doVinc[2][_nY,1]))
        If SC6->(Deleted())
           Loop
        EndIf    	
        
        If _cRet = "LBOK"//REALIZA O CONSUMO DA SB2 *** MARCA ***

            If (_nPos:=aScan(_aSB2, {|x| x[1] == SC6->C6_FILIAL .And. x[2] == SC6->C6_PRODUTO .And. x[7] = SC6->C6_LOCAL })) > 0 				

                //            Disponivel      //- reservas dos gerentes + reserva do gerente do pedidos posicinado
                _nSaldoDisp:=_aSB2[_nPos][06] //- _aSB2[_nPos][12]    //+ _nReservGer

               _aSB2[_nPos][09] += SC6->C6_UNSVEN //Quantidade Carteira na 2ª UM - itens do pedido // SOMTORIA TODAS AS BOLINHAS

               If _nSaldoDisp  >= SC6->C6_QTDVEN //.AND. (_nReservGer = 0 .Or. _nReservGer > SC6->C6_QTDVEN) // <<<<<<<<<<<<<<<<<<<<<<<<<<<
                  
                  _aSB2[_nPos][06] -= SC6->C6_QTDVEN // SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP // DISPONIVEL

                   _aSC6doVinc[2][_nY,2]:=.T. //Marca o item que TEM ESTOQUE PARA Gravar ZY8 (MOMS66ZY8 ())

                    //BOTÃO: "VER / CORTAR Itens Pedido""
                    _nQtdeATend := SC6->C6_QTDVEN
                    _nQtdeFalta := 0
                    _nPesoFalta := 0
                   
                   //CARREGA FATOR DE CONVERSÃO SE EXISTIR
                   _nfator := 1
                   If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
                      If SB1->B1_CONV == 0
                         If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                               _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                         EndIf
                      Else
                         _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
                      EndIf
                   EndIf			
                   //BOTÃO: "VER / CORTAR Itens Pedido""
                   _aSC6doVinc[2][_nY,3]:=(_nQtdeATend*_nfator)
                   _aSC6doVinc[2][_nY,4]:=(_nQtdeFalta*_nfator)//QTDE FALTANTE
                   _aSC6doVinc[2][_nY,5]:=_nPesoFalta

                Else

                    _lTemEstoque:=.F.
                    _cProdSEst  +=CRLF+AllTrim(SC6->C6_PRODUTO)+"/ Qtde "+AllTrim(TRANS(SC6->C6_QTDVEN,"@E 999,999,999,999.999")) +" > Saldo "+AllTrim(TRANS(_nSaldoDisp,"@E 999,999,999,999.999"))+" (V)"

                EndIf
                
            EndIf

        
        ElseIf _cRet = "LBNO"//ACRESCENTA NO ESTOQUE DE VOLTA  *** DESMARCA ***
           
            _aSB2[_nPos][06]+= SC6->C6_QTDVEN // (SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP) // DISPONIVEL			    
            //BOTÃO: "VER / CORTAR Itens Pedido""
            _aSC6doVinc[2][_nY,3]:=0//_nQtdeATend
            _aSC6doVinc[2][_nY,4]:=0//_nQtdeFalta
            _aSC6doVinc[2][_nY,5]:=0//_nPesoFalta

       EndIf     

   Next _nY
  
EndIf
//VINCULADOS

If !_lTemEstoque 

   _aSB2:= MOMS66aSB2(_aSB2,"VOLTA") //VOLTA O ESTOQUE COMO ESTAVA
   U_ITMsg("SEM ESTOQUE PARA OS PRODUTOS: "+_cProdSEst,'Atenção!',"Desmarque outro Pedido que tenha esses itens, para obter mais saldo.",1)

   Return .F.//SAIR SEM FAZER NADA

EndIf
//ESTOQUE


//CAPACIDADE
_lPalitizada   :=_aTelaPedidos[_nX][_nPosTPCA] = "1"  //C5_I_TIPCA
_nPedTotPalete :=_aTelaPedidos[_nX][_nPosPalete]      //QTDE DE PALETES DO PEDIDO 
_nPesoPedido   :=_aTelaPedidos[_nX][_nPosPesBru]      //SC5->C5_I_PESBR
If nPosVinc > 0 
  _nPedTotPalete+=_aTelaPedidos[nPosVinc][_nPosPalete]//QTDE DE PALETES DO PEDIDO 
  _nPesoPedido  +=_aTelaPedidos[nPosVinc][_nPosPesBru]//SC5->C5_I_PESBR
EndIf
_lTemCapacidade:=.T.

If _cRet = "LBOK"//REALIZA O CONSUMO DA CAPACIDADE *** MARCA ***

   If _lPalitizada// COM PALETE
      
      _nTotPalsLib +=_nPedTotPalete // SOMA
      
      If _nTotPalsLib <= _nPaleCapacFil//LIIMITE DA CAPACIDADE DE PALETES DA FILIAL
      
         _lTemCapacidade:=.T.
         If nPosVinc <> 0//Pedido Vinculdo se tiver
            _cObs:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999,999"))+" ) < "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999,999")+" Paletes ")
         Else
             _cObs:="Pedido DENTRO da capacidade: "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999,999"))+" ) < "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999,999")+" Paletes ")
         EndIf   
      
      Else
        
         _lTemCapacidade:=.F.
         If nPosVinc <> 0//Pedido Vinculdo se tiver
            U_ITMsg("Pedidos ("+_aTelaPedidos[_nX,_nPosPed]+"+"+_aTelaPedidos[_nX,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999,999"))+" ) > "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999,999"))+" Paletes ",'Atenção!',"Desmarque outro Pedido que tenha esses itens, para obter mais capacidade.",1)
         Else
            U_ITMsg("Pedido FORA da capacidade: ( "+AllTrim(TRANS((_nTotPalsLib-_nPedTotPalete),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPedTotPalete,"@E 999,999,999,999"))+" ) > "+AllTrim(TRANS( _nPaleCapacFil,"@E 999,999,999,999"))+" Paletes ",'Atenção!',"Desmarque outro Pedido que tenha esses itens, para obter mais capacidade.",1)
         EndIf
   
         _nTotPalsLib -=_nPedTotPalete// DIMIMINUI O QUE SOMOU ACIMA
   
      EndIf
   
   Else//SEM PALETE / POR PESO
   
      _nTotPesoLib +=_nPesoPedido// SOMA
      
      If _nTotPesoLib <= _nPesoCapacFil//LIIMITE DA CAPACIDADE DE PESO DA FILIAL
         _lTemCapacidade:=.T.
         
         If nPosVinc <> 0//PEDIDO VINCULDO SE TIVER
            _cObs:="Pedido ("+_aTelaPedidos[nPosVinc,_nPosPed]+"+"+_aTelaPedidos[nPosVinc,_nPosPedVin]+") DENTRO da capacidade: "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999,999"))+" ) < KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999,999"))//+If(!Empty(_aTelaPedidos[nPosVinc,_nPosObs])," / "+_aTelaPedidos[nPosVinc,_nPosObs],"")
         Else
            _cObs:="Pedido DENTRO da capacidade: "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999,999"))+" ) < KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999,999"))
         EndIf
      Else
         _lTemCapacidade:=.F.

         If nPosVinc <> 0//PEDIDO VINCULDO SE TIVER
            U_ITMsg("Pedidos ("+_aTelaPedidos[_nX,_nPosPed]+"+"+_aTelaPedidos[_nX,_nPosPedVin]+") FORA da capacidade: ( "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999,999"))+" ) > KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999,999")),'Atenção!',"Desmarque outro Pedido que tenha esses itens, para obter mais capacidade.",1)
         Else
            U_ITMsg("Pedido FORA da capacidade: ( "+AllTrim(TRANS((_nTotPesoLib-_nPesoPedido),"@E 999,999,999,999"))+" + "+AllTrim(TRANS( _nPesoPedido,"@E 999,999,999,999"))+" ) > KG "+AllTrim(TRANS( _nPesoCapacFil,"@E 999,999,999,999")),'Atenção!',"Desmarque outro Pedido que tenha esses itens, para obter mais capacidade.",1)
         EndIf
   
         _nTotPesoLib -=_nPesoPedido// DIMINMUI O QUE SOMOU ACIMA
   
      EndIf
   EndIf

ElseIf _cRet = "LBNO"//ACRESCENTA NO ESTOQUE DE VOLTA  *** DESMARCA ***

   If _lPalitizada
      _nTotPalsLib -=_nPedTotPalete
   Else
      _nTotPesoLib -=_nPesoPedido
   EndIf
   
   _aTelaPedidos[_nX,_nPosObs]:="(D) "+StrTran(_aTelaPedidos[_nX,_nPosObs],"(M) ", "")//(M) DE MARCADO / (D) DE DESMARCADO
   If nPosVinc > 0 //PEDIDO VINCULDO SE TIVER
      _aTelaPedidos[nPosVinc,nPosOK     ]:=_cRet
      _aTelaPedidos[nPosVinc,nPosOK2    ]:=_cRet
      _aTelaPedidos[nPosVinc,_nPosObs   ]:="(D) "+StrTran(_aTelaPedidos[nPosVinc,_nPosObs],"(M) ", "")//(M) DE MARCADO / (D) DE DESMARCADO
   EndIf
   
   If !Empty(_aTelaPedidos[_nX][nPosC1])
      _cCodCarga:=_aTelaPedidos[_nX][nPosC1]
      For _nY := 1 TO Len(_aTelaPedidos)// Loop NOS PEDIDOS
          If _aTelaPedidos[_nY,nPosC1] = _cCodCarga
             _aTelaPedidos[_nY,nPosC1]:="  "//LIMPA A MARCACOES DA CARGAS C1 ou C2 ou C3...
          EndIf
      Next   
   EndIf

   Return .T. //SAIDA NO DESMARCA

EndIf     

If !_lTemCapacidade
   _aSB2:= MOMS66aSB2(_aSB2,"VOLTA") //VOLTA O ESTOQUE COMO ESTAVA
   Return .F. // SAIR SEM FAZER NADA
EndIf

_aTelaPedidos[_nX,_nPosRecnos]:=_aSC6_do_PV
_aTelaPedidos[_nX,nPosCar    ]:="ENABLE"     //COLUNA CARREGAMENTO
_aTelaPedidos[_nX,_nPosEst   ]:="ENABLE"     //COLUNA ESTOQUE
_aTelaPedidos[_nX,_nPosCap   ]:="ENABLE"     //COLUNA CAPACIDADE
_aTelaPedidos[_nX,_nPosObs   ]:="(M) "+_cObs //(M) DE MARCADO
If nPosVinc > 0 //PEDIDO VINCULDO SE TIVER
   _aTelaPedidos[nPosVinc,_nPosRecnos]:=_aSC6doVinc
   _aTelaPedidos[nPosVinc,nPosOK     ]:=_cRet
   _aTelaPedidos[nPosVinc,nPosOK2    ]:=_cRet
   _aTelaPedidos[nPosVinc,nPosCar    ]:="ENABLE"    // COLUNA CARREGAMENTO
   _aTelaPedidos[nPosVinc,_nPosEst   ]:="ENABLE"    // COLUNA ESTOQUE
   _aTelaPedidos[nPosVinc,_nPosCap   ]:="ENABLE"    // COLUNA CAPACIDADE
   _aTelaPedidos[nPosVinc,_nPosObs   ]:="(M) "+_cObs//(M) DE MARCADO
EndIf

Return .T. //SAIDA DA MARCACAO

/*
===============================================================================================================================
Programa----------: MOMS66VCarga
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: VALIDA OS PEDIDOS MARCADOS NAS MESO PARA FORMAR UMA CARGA
Parametros--------: Nenhum
Retorno-----------: .T. ou .F.
===============================================================================================================================
*/
Static Function MOMS66VCarga()

Local _nX           :=0
Local _nLMesoPesoLib:=0
Local _nLMesoPalsLib:=0
Local _lCargaOK     :=.F.
Local _cTipCarga    :=""
Local _cCodCarga    :=""//C1,C2,C3,C4...

If !lClicouMarca
   Return .F. 
EndIf

If !MOMS66Acesso()
   Return .F.
EndIf

If (oMsMGet:=MOMS66Obj()) = NIL 
   Return .F.
EndIf

_aTelaPedidos:=oMsMGet:aCols

For _nX := 1 TO Len(_aTelaPedidos)

     If _aTelaPedidos[_nX][nPosOK2] <> "LBOK" //COLUNA REAL
        Loop
     EndIf

     If _aTelaPedidos[_nX][nPosC1] > _cCodCarga
        _cCodCarga:=_aTelaPedidos[_nX][nPosC1]
     EndIf

     If !Empty(_aTelaPedidos[_nX][nPosC1])
        Loop
      EndIf

     If Empty(_cTipCarga)
        _cTipCarga :=_aTelaPedidos[_nX][_nPosTPDACA]
     ElseIf _cTipCarga <>_aTelaPedidos[_nX][_nPosTPDACA]
        _cTipCarga:="DIFERENTE"
     EndIf

     _nLMesoPalsLib+=_aTelaPedidos[_nX][_nPosPalete]//Qtde de Paletes do Pedido 
     _nLMesoPesoLib+=_aTelaPedidos[_nX][_nPosPesBru]//SC5->C5_I_PESBR 

Next

If  (_cTipCarga = "DIFERENTE") //(_nTMesoPesoLib > 0 .And. _nTMesoPalsLib > 0) .Or.
   U_ITMsg("Pedidos marcados devem ter o mesmo tipo de carga",'Atenção!',"Ex.: Carga Seca com Carga Seca , Refrigerada com Refrigerada... ",1)
   Return .F.// SAI AQUI
EndIf

If _nLMesoPalsLib > 0 .And. INT(_nLMesoPalsLib) = _nLMesoPalsLib .And. StrZero(_nLMesoPalsLib,2,0) $ _cMultPall
   U_ITMsg("Carga Fechada com SUCESSO com "+StrZero(_nLMesoPalsLib,2,0)+" Palete(s)",'Atenção!',"Cargas Palitizadas fecham com "+_cMultPall,2)
   _lCargaOK:=.T.
EndIf

If !_lCargaOK .And. _nLMesoPesoLib > 0 .And. StrZero( Round((_nLMesoPesoLib/1000),0)  ,2,0) $ _cMultPeso 
   U_ITMsg("Carga Fechada com SUCESSO com "+StrZero( Round((_nLMesoPesoLib/1000),0),2,0)+" Tonelada(s).",'Atenção!',"Cargas Batidas fecham com "+_cMultPeso,2)
   _lCargaOK:=.T.
EndIf

If _lCargaOK

   If !Empty(_cCodCarga)
      _cCodCarga:=Soma1(_cCodCarga)
   Else
      _cCodCarga:="C1"
   EndIf

   For _nX := 1 TO Len(_aTelaPedidos)
     If _aTelaPedidos[_nX][nPosOK2] = "LBOK" //COLUNA REAL
        If Empty(_aTelaPedidos[_nX][nPosC1])
           _aTelaPedidos[_nX][nPosC1] := _cCodCarga
        EndIf
     EndIf
   Next

Else
   
   _cMensagem:=""
   _cSolucao:=""
   If _nLMesoPalsLib > 0
      _cMensagem:="Carga PALITIZADA ainda não fechou, esta com "+AllTrim(TRANS(_nLMesoPalsLib,"@E 9,999.999"))+" Palete(s). Tem que ser "+StrZero(INT(_nLMesoPalsLib),2,0)+" sem sobras."
      _cSolucao :="Cargas PALITIZADAS fecham com "+_cMultPall+ " Palete(s)."
   EndIf   
   If _nLMesoPesoLib > 0 
      _cMensagem+=CRLF+"Carga BATIDA ainda não fechou, esta com "+AllTrim(TRANS((_nLMesoPesoLib/1000),"@E 999,999.999"))+" Tonelada(s). Considera: "+StrZero( Round((_nLMesoPesoLib/1000),0),2,0)
      _cSolucao +=CRLF+"Cargas BATIDAS fecham com "+_cMultPeso+" Toneladas"
   EndIf
   If !Empty(_cMensagem)
      U_ITMsg(_cMensagem,'Atenção!',_cSolucao,2)
      Return .F. // SAI AQUI
   EndIf

EndIf

_cRQtdeCarrega:=" "//Se não tem marcados ou marcados sem coluna carga em branco : LIMPA
oSAYValCar:Refresh()

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66Reproc
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: VALIDA OS PEDIDOS MARCADOS NAS MESO PARA FORMAR UMA CARGA
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS66Reproc(oProc)

Local P 

// MARCADOS
_aSB2Inic:={}
oProc:cCaption :="1/3 - Reprocessando marcados Cargas TOP1..."
ProcessMessages()
_aPedTOP1:=oBrwTOP1:aCols
_aPedTOP1:= MOMS66PC(_aPedTOP1,"M",.T.,.F.,,aFoders1[1])//ZERA A ARRAY _aSB2 NO PRIMEIRO PARA LER O ESTOQUE DE NOVO *********************

oProc:cCaption :="2/3 - Reprocessando marcados Cargas Fechadas..."
ProcessMessages()
_aPedCAFE:=oBrwCaFe:aCols
_aPedCAFE:= MOMS66PC(_aPedCAFE,"M",.F.,.F.,,aFoders1[2])

oProc:cCaption :="3/3 - Reprocessando marcados Pedidos Fora de Padrão..."
ProcessMessages()
_aPedFORA:=oBrwFORA:aCols
_aPedFORA:= MOMS66PC(_aPedFORA,"M",.F.,.F.,,aFoders1[3])

For P := 1 TO Len(aPedsReg1)     
    oProc:cCaption :="1/5 - Reprocessando marcados  "+aFoldReg1[P]
    ProcessMessages()
    If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg1[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       aPedsReg1[P]:= MOMS66PC(_aPedPasta,"M",.F.,.F.)   
    EndIf
Next
For P := 1 TO Len(aPedsReg2) 
    oProc:cCaption :="2/5 - Reprocessando marcados  "+aFoldReg2[P]
    ProcessMessages()
    If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg2[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       aPedsReg2[P]:= MOMS66PC(_aPedPasta,"M",.F.,.F.)   
    EndIf
Next
For P := 1 TO Len(aPedsReg3) 
    oProc:cCaption :="3/5 - Reprocessando marcados  "+aFoldReg3[P]
    ProcessMessages()
    If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg3[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       aPedsReg3[P]:= MOMS66PC(_aPedPasta,"M",.F.,.F.)   
    EndIf
Next
For P := 1 TO Len(aPedsReg4) 
    oProc:cCaption :="4/5 - Reprocessando marcados  "+aFoldReg4[P]
    ProcessMessages()
    If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg4[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       aPedsReg4[P]:= MOMS66PC(_aPedPasta,"M",.F.,.F.)   
    EndIf
Next
For P := 1 TO Len(aPedsReg5) 
    oProc:cCaption :="5/5 - Reprocessando marcados  "+aFoldReg5[P]
    ProcessMessages()
    If (nPos:=aScan(aBrowses, {|B| B[1] == aFoldReg5[P] } )) > 0
       oMsMGet:=aBrowses[nPos,2]
       _aPedPasta:=oMsMGet:aCols
       aPedsReg5[P]:= MOMS66PC(_aPedPasta,"M",.F.,.F.)   
    EndIf
Next

//DESMARCADOS

_aSB2:=MOMS66aSB2(_aSB2,"SALVA")//SALVA ESTOQUE ANTES PAREA PROCESSAR CADA PASTA DOS DEMACADOS COM ESSA FOTO
_nBKPPesoLib  := _nTotPesoLib   //Salva totais  antes de processar cada pasta dos demacados
_nBKPPalsLib  := _nTotPalsLib   //Salva totais  antes de processar cada pasta dos demacados
_nBKPGerFin   := _nTotGerFin    //Salva totais  antes de processar cada pasta dos demacados
_nBKPNaoGerFin:= _nTotNaoGerFin //Salva totais  antes de processar cada pasta dos demacados

oProc:cCaption :="1/3 - Reprocessando desmarcados Cargas TOP1..."
ProcessMessages()
_aPedTOP1:= MOMS66PC(_aPedTOP1,"D",.F.,.T.,,aFoders1[1])

oProc:cCaption :="2/3 - Reprocessando desmarcados Cargas Fechadas..."
ProcessMessages()
_aPedCAFE:= MOMS66PC(_aPedCAFE,"D",.F.,.T.,,aFoders1[2])

oProc:cCaption :="3/3 - Reprocessando marcados Pedidos Fora de Padrão..."
ProcessMessages()
_aPedFORA:= MOMS66PC(_aPedFORA,"D",.F.,.T.,,aFoders1[3])

If Len(aPedsReg1) > 0//Len(aFolderRGBR) >= 1 // CARGAS POR MESO DA REGIAO 1 ************************** //
   oProc:cCaption := ("1/5 - Reprocessando desmarcados: "+aFolderRGBR[1] )
   ProcessMessages()
   For P := 1 TO Len(aPedsReg1) 
       _aPedPasta:=aPedsReg1[P]
       aPedsReg1[P]:= MOMS66PC(_aPedPasta,"D",.F.,.T.)   
   Next
EndIf

If Len(aPedsReg2) > 0//CARGAS POR MESO DA REGIAO 2 ************************** //
   oProc:cCaption := ("2/5 - Reprocessando desmarcados: "+aFolderRGBR[2] )
   ProcessMessages()
   For P := 1 TO Len(aPedsReg2) 
       _aPedPasta:=aPedsReg2[P]
       aPedsReg2[P]:= MOMS66PC(_aPedPasta,"D",.F.,.T.)   
   Next
EndIf

If Len(aPedsReg3) > 0//CARGAS POR MESO DA REGIAO 3 ************************** //
   oProc:cCaption := ("3/5 - Reprocessando desmarcados: "+aFolderRGBR[3] )
   ProcessMessages()
   For P := 1 TO Len(aPedsReg3) 
       _aPedPasta:=aPedsReg3[P]
       aPedsReg3[P]:= MOMS66PC(_aPedPasta,"D",.F.,.T.)   
   Next
EndIf

If Len(aPedsReg4) > 0//CARGAS POR MESO DA REGIAO 4 ************************** //
   oProc:cCaption := ("4/5 - Reprocessando desmarcados: "+aFolderRGBR[4] )
   ProcessMessages()
   For P := 1 TO Len(aPedsReg4) 
       _aPedPasta:=aPedsReg4[P]
       aPedsReg4[P]:= MOMS66PC(_aPedPasta,"D",.F.,.T.)   
   Next
EndIf

If Len(aPedsReg5) > 0//CARGAS POR MESO DA REGIAO 5 ************************** //
   oProc:cCaption := ("5/5 - Reprocessando desmarcados: "+aFolderRGBR[5] )
   ProcessMessages()
   For P := 1 TO Len(aPedsReg5) 
       _aPedPasta:=aPedsReg5[P]              
       aPedsReg5[P]:= MOMS66PC(_aPedPasta,"D",.F.,.T.)   
   Next
EndIf
_lSomaPontFat := .F.            //Desliga aqui de novo pq o lZera dentro da funcao MOMS66PC () RELIGA
_aSB2:=MOMS66aSB2(_aSB2,"VOLTA")//RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotPesoLib  := _nBKPPesoLib   //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotPalsLib  := _nBKPPalsLib   //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotGerFin   := _nBKPGerFin    //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotNaoGerFin:= _nBKPNaoGerFin //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO

_lEfetivar  := .T.//ATIVA BOTÃO GERAR
lClicouMarca:= .F.//Desativa a atualização na troca de pasta

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66Atu2
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: ATUALIZA OS PEDIDOS DESMARCADO DO BROWSE POSICIONADO
Parametros--------: oMsMGet,oProc
Retorno-----------: Nenhum
===============================================================================================================================
*/
Static Function MOMS66Atu2(oMsMGet,oProc)

If !lClicouMarca
   Return .F. 
EndIf

If oMsMGet = NIL .And. (oMsMGet:=MOMS66Obj()) = NIL 
   Return .F.
EndIf
_aTelaPedidos := oMsMGet:aCols  //CARREGA
_aSB2:=MOMS66aSB2(_aSB2,"SALVA")//SALVA ESTOQUE ANTES PAREA PROCESSAR CADA PASTA DOS DEMACADOS COM ESSA FOTO
_nBKPPesoLib  := _nTotPesoLib   //SALVA TOTAIS  ANTES DE PROCESSAR CADA PASTA DOS DEMACADOS
_nBKPPalsLib  := _nTotPalsLib   //SALVA TOTAIS  ANTES DE PROCESSAR CADA PASTA DOS DEMACADOS
_nBKPGerFin   := _nTotGerFin    //SALVA TOTAIS  ANTES DE PROCESSAR CADA PASTA DOS DEMACADOS
_nBKPNaoGerFin:= _nTotNaoGerFin //SALVA TOTAIS  ANTES DE PROCESSAR CADA PASTA DOS DEMACADOS

_aTelaPedidos:= MOMS66PC(_aTelaPedidos,"D2",.F.,.T.,oProc)

_aSB2:=MOMS66aSB2(_aSB2,"VOLTA")  //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotPesoLib  := _nBKPPesoLib     //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotPalsLib  := _nBKPPalsLib     //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotGerFin   := _nBKPGerFin      //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
_nTotNaoGerFin:= _nBKPNaoGerFin   //RESTAURA AQUI PQ O ESTOQUE DOS DESMACARDOS É SIMULACAO
oMsMGet:aCols := _aTelaPedidos    //DEVOLVE ATUALIZADO

oMsMGet:oBrowse:Refresh()
oMsMGet:oBrowse:SetFocus()

Return .T.

/*
===============================================================================================================================
Programa----------: MOMS66aSB2
Autor-------------: Alex Wallauer
Data da Criacao---: 18/03/2024
Descrição---------: SALVA E VOLTA O SALDO DO PRODUTO DA _aSB2
                    POSICAO PARA SALVAR O SALDO ANTERIOR A SIMULACAO: INICIA IGUAL PQ NA SIMULACAO PODE TER ITENS NOVOS NA SIMULACAO
Parametros--------: _aSB2,cManut: "SALVA ou "VOLTA"
Retorno-----------: _aSB2
===============================================================================================================================
*/
Static Function MOMS66aSB2(_aSB2,cManut)

Local L
If Len(_aSB2) > 0

   For L := 1 TO Len(_aSB2)
       If cManut = "SALVA"
          _aSB2[L,13] := _aSB2[L,06] // SALVA O SALDO DE ANTES DA SIMULACAO
       Else//cManut = "VOLTA"
          _aSB2[L,06] := _aSB2[L,13] // VOLTA O SALDO DEPOIS DA SIMULACAO
       EndIf
   Next
   
EndIf

Return _aSB2

/*
===============================================================================================================================
Programa----------: MOMS66PreGrv
Autor-------------: Alex Walaluer
Data da Criacao---: 31/07/2024
Descrição---------: Funcao para fazer a gravação dos dados por grupo de pediso de uma carga da meso
Parametros--------: _aPedPasta,oProc,_cPasta
Retorno-----------: .T.
===============================================================================================================================
*/
Static Function MOMS66PreGrv(_aPedPasta,oProc,_cPasta)

Local B
Local _aPedsCarga:={}
       
For B := 1 TO Len(_aPedPasta) 
   //PASTAS DAS MESORREGIÕES COM CARGA VALIDADA
   If _aPedPasta[B,nPosCar] == "ENABLE" .AND.;//CARREGAR SIM 
     _aPedPasta[B,nPosOK2] == "LBOK"   .AND.;//MARCADO REAL
     !Empty(_aPedPasta[B][nPosC1])           //MARCADO COM CARGA VALIDADA
     If (nPos:=aScan(_aPedsCarga,{|P| P[1] == _aPedPasta[B][nPosC1]})) = 0 
        aAdd(_aPedsCarga,{_aPedPasta[B][nPosC1],{ _aPedPasta[B] } , "GERAR" })//M->C5_I_AGRUP
     Else
        aAdd(_aPedsCarga[nPos,2], _aPedPasta[B] )
     EndIf
   Else
     If (nPos:=aScan(_aPedsCarga,{|P| P[1] == "SEMCARGA" })) = 0 
        aAdd(_aPedsCarga,{ "SEMCARGA" ,{ _aPedPasta[B]  } , " " })
     Else
        aAdd(_aPedsCarga[nPos,2], _aPedPasta[B] )
     EndIf
   EndIf		  
Next
For B := 1 TO Len(_aPedsCarga)
    BEGIN TRANSACTION
     If _aPedsCarga[B,3] == "GERAR"
        If SC5->(FIELDPOS("C5_I_AGRUP")) > 0
           _aPedsCarga[B,3]:= U_RetCodGru()//Gera codigo do C5_I_AGRUP
        EndIf
     EndIf
     MOMS66Grv(_aPedsCarga[B,2],oProc,.T.,_cPasta,_aPedsCarga[B,3])
    END TRANSACTION
Next

Return .T.
/*
===============================================================================================================================
Programa----------: RetCodGru
Autor-------------: Alex Walaluer
Data da Criacao---: 30/07/2024
Descrição---------: Funcao utilizada para retornar o codigo do grupo de pedidods de uma Carga.
Parametros--------: Nenhum
Retorno-----------: _cCodigo: Grava no campo C5_I_AGRUP
===============================================================================================================================
*/
User Function RetCodGru()//Grava no campo C5_I_AGRUP

Local _cQuery   := ""
Local _cAlias:= GetNextAlias()  
Local _cCodigo  := ""

_cQuery := " SELECT COALESCE( MAX( C5_I_AGRUP ) , '0' ) CODIGO "
_cQuery += " FROM " + RetSqlName("SC5") + " "
_cQuery += " WHERE	D_E_L_E_T_	= ' ' "

DBUseArea( .T. , "TOPCONN" , TcGenQry(,,_cQuery) , _cAlias , .T. , .F. )
DBSelectArea(_cAlias)
(_cAlias)->( DBGoTop() )

If AllTrim( (_cAlias)->CODIGO ) == '0'
   _cCodigo := '000001'
Else  
   _cCodigo :=  Soma1( (_cAlias)->CODIGO) 
EndIf

While !MayIUseCode( "C5_I_AGRUP"+_cCodigo )	        //verifica se esta na memoria, sendo usado
   _cCodigo :=  Soma1(_cCodigo) 	// busca o proximo numero disponivel
EndDo

(_cAlias)->( DBCloseArea() )

Return( _cCodigo ) //Grava no campo C5_I_AGRUP

/*
===============================================================================================================================
Programa--------: MOMS66CLB
Autor-----------: Alex Wallauer
Data da Criacao-: 28/06/2022
Descrição-------: Se Considerar liberação de estoque? = SIM Monta a tela para pegar as quantidade de estoque
Parametros------: _aTelaPedidos
Retorno---------: NENHUM
===============================================================================================================================
*/
Static Function MOMS66CLB(_aTelaPedidos,oProc)

Local _nX := 0 , L
Local _nY := 0
Local _lSomaPTer:= .F.
Local _aSB2:={}
Local _cTotGeral:=AllTrim(Str(Len(_aTelaPedidos)))

SB1->(DBSetOrder(1))
SB2->(DBSetOrder(1)) //B2_FILIAL+B2_COD+B2_LOCAL
nConta:=0

For _nX := 1 TO Len(_aTelaPedidos)

   nConta++
   oProc:cCaption := ("2.1-Analizando Estoques - "+StrZero(nConta,5) +" de "+ _cTotGeral )
   ProcessMessages()

    If _aTelaPedidos[_nX,nPosCar]  $ LEGENDAS_ABCP
       Loop
    EndIf

    _aSC6_do_PV:=_aTelaPedidos[_nX][_nPosRecnos]

    For _nY := 1 TO Len(_aSC6_do_PV[2])
        SC6->(DBGoTo(_aSC6_do_PV[2][_nY,1]))
        If SC6->(Deleted())
           Loop
        EndIf

        If SB2->(DBSeek(SC6->C6_FILIAL+SC6->C6_PRODUTO+SC6->C6_LOCAL)) .AND.;
           SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO)) .And. SB1->B1_TIPO = 'PA'.AND. ;
           (aScan(_aSB2, {|x| x[1] == SB2->B2_COD .And. x[3] == SB2->B2_LOCAL})) = 0
        
           //Carrega fator de conversão se existir
           _nfator := 1
           If SB1->(DBSeek(xFilial("SB1")+SC6->C6_PRODUTO))
              If SB1->B1_CONV == 0
                 If SB1->B1_I_QQUEI == 'S' .And. SB1->B1_I_FATCO > 0
                      _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_I_FATCO,SB1->B1_I_FATCO)
                 EndIf
              Else
                 _nfator := If(SB1->B1_TIPCONV=="D", 1/SB1->B1_CONV,SB1->B1_CONV)
              EndIf
           EndIf

           _cDescricao   := AllTrim(SB1->B1_DESC)
           _lSomaPTer    := (SC6->C6_FILIAL $ _cFilTer .And. SC6->C6_LOCAL $ _cLocTer)
           _nSaldoDisp   := SB2->B2_QATU - SB2->B2_RESERVA - SB2->B2_QEMP + If(_lSomaPTer,SB2->B2_QNPT,0)
           _nSaldoDisp   := _nSaldoDisp*_nfator
           _nPoderTer    := If(_lSomaPTer,SB2->B2_QNPT,0)
           _nPoderTer    := _nPoderTer*_nfator
           If SB2->(FIELDPOS("B2_I_QLIBE")) > 0
              M->B2_I_QLIBE := SB2->B2_I_QLIBE
              M->B2_2_QLIBE := SB2->B2_I_QLIBE*_nfator
           Else
              M->B2_I_QLIBE := 0
              M->B2_2_QLIBE := 0
           EndIf

           aAdd(_aSB2, {SB2->B2_COD    ,;//01 - PRODUTO
                        _cDescricao    ,;//02 - DESCRICAO DO PRODUTO
                        SB2->B2_LOCAL  ,;//03 - ARMAZEM
                        SC6->C6_SEGUM  ,;//04 - 2 UM 
                        M->B2_2_QLIBE  ,;//05 - 2 UM B2_I_QLIBE
                        SC6->C6_UM     ,;//06 - 1 UM 
                        M->B2_I_QLIBE  ,;//07 - 1 UM B2_I_QLIBE
                        _nSaldoDisp    ,;//08 - Disponivel Final 2 UM 
                        _nPoderTer     ,;//09 - Poder de 3o em 2 UM
                        SB2->(RECNO()) ,;//10 - Registro do SB2
                        .F.            })//11 - Coluna de delecao
       EndIf
    
    Next 

Next _nX

aHeader2:={}
//                     1                  2             3                            4          5        6        7       8       9       10          11      12        13       14         15        16   17
//dd(aHeader2,{trim(x3_titulo)     ,x3_campo    ,x3_picture                 ,x3_tamanho,x3_decimal,x3_valid,x3_usado,x3_tipo, x3_f3,x3_context,	x3_cbox,x3_relacao,x3_when,X3_TRIGGER,	X3_PICTVAR,.F.,.F.})
aAdd(aHeader2,{"Produto"           ,"WK_PRODUT ","@!"                       ,13,0,"            ","","C","      ","","","",".F."})//01    
nPosProde := Len(aHeader2)
aAdd(aHeader2,{"Descricao"         ,"WK_DESCRIT","@!"                       ,45,0,"            ","","C","      ","","","",".F."})//02
aAdd(aHeader2,{"Armazem"           ,"WK_LOCAL"  ,"@!"                       ,02,0,"            ","","C","      ","","","",".F."})//03    
aAdd(aHeader2,{"2 UM"              ,"C6_SEGUM"  ,"@!"                       ,03,0,"            ","","C","      ","","","",".F."})//04    
aAdd(aHeader2,{"Qtde Liberada 2 UM","B2_2_QLIBE","@E 9,999,999,999,999.9999",18,4,"U_M66Valid()","","N","      ","","","",".T."})//05
nPos2QLIBE:= Len(aHeader2)
aAdd(aHeader2,{"1 UM"              ,"C6_UM"     ,"@!"                       ,03,0,"            ","","C","      ","","","",".F."})//06    
aAdd(aHeader2,{"Qtde Liberada 1 UM","B2_1_QLIBE","@E 9,999,999,999,999.9999",18,4,"U_M66Valid()","","N","      ","","","",".T."})//07    
nPosQLIBE := Len(aHeader2)
aAdd(aHeader2,{"Disponivel 2 UM"    ,"WK_SALDOIT","@E 9,999,999,999,999.9999",18,4,"           ","","N","      ","","","",".F."})//08
nPosDispo := Len(aHeader2)
aAdd(aHeader2,{"Em poder 3o 2 UM"  ,"WK_PODER3" ,"@E 9,999,999,999,999.9999",18,4,"            ","","N","      ","","","",".F."})//09
nPosPoder3:= Len(aHeader2)
   
If Len(_aSB2) > 0
  _nGDAction:= GD_UPDATE 
Else
   U_ITMsg("Não há itens de PA com o filtro atual para poder ajustar.",'Atenção!',,1)
   Return 
EndIf

   // pega tamanhos das telas
   _aSize := MsAdvSize()
   _aInfoG := { _aSize[1] , _aSize[2] , _aSize[3] , _aSize[4] , 1 , 1 }
   
   aGObjects := {}
   aAdd( aGObjects, { 100, 100, .T., .T. } )
   
   aPosGObj := MsObjSize( _aInfoG , aGObjects )

   _bEfetivar :={|| If(U_ITMsg("Confirma GRAVACAO ?",'Atenção!',,2,2,2),(_lGrava:=.T.,oDlgGer:End()),) }
   _bSair     :={|| (_lGrava:=.F.,oDlgGer:End())  }
   
   _cTitulo:="MANUTENÇÃO DO SALDO / FILIAL: "+cFilAnt
   
   While .T.

      _lGrava:=.F.

      DEFINE MSDIALOG oDlgGer TITLE _cTitulo OF oMainWnd PIXEL FROM _aSize[7],0 TO _aSize[6],_aSize[5]

                                  //[ nTop]          , [ nLeft]   , [ nBottom] , [ nRight ] , [ nStyle]  ,cLinhaOk,cTudoOk,cIniCpos, [ aAlter], [ nFreeze], [ nMax], [ cFieldOk], [ cSuperDel], [ cDelOk], [ oWnd], [ aPartHeader], [ aParCols], [ uChange], [ cTela], [ aColsSize] 
         oMsMGetG := MsNewGetDados():New((aPosGObj[1,1]),aPosGObj[1,2],aPosGObj[1,3],aPosGObj[1,4],_nGDAction,        ,       ,        ,          ,           ,        ,            ,             ,          ,oDlgGer ,aHeader2       , _aSB2 ,)
       
        oDlgGer:lMaximized:=.T.
          
      ACTIVATE MSDIALOG oDlgGer ON INIT (EnchoiceBar(oDlgGer,_bEfetivar,_bSair,,) , oMsMGetG:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT )
   
      If _lGrava 
         _aGerAux:=oMsMGetG:ACOLS
         nConta:=0
         nGravou:=0
         _cTotGeral:=AllTrim(Str(Len(_aGerAux)))
         For L := 1 TO Len(_aGerAux)
             nConta++
             oProc:cCaption := ("2.2-Gravando Estoques - "+StrZero(nConta,5) +" de "+ _cTotGeral )
             ProcessMessages()
             If !aTail(_aGerAux[L])// Se Linha não Deletada
                nRecSB2:=_aGerAux[L][Len(_aGerAux[L])-1]
                If !Empty(nRecSB2)
                   SB2->(DBGoTo(nRecSB2))
                   If SB2->B2_I_QLIBE <> _aGerAux[L][nPosQLIBE]
                      SB2->(RecLock("SB2",.F.))
                      SB2->B2_I_QLIBE:=_aGerAux[L][nPosQLIBE]
                      SB2->(MSUnLock())
                      nGravou++
                   EndIf
                EndIf
             EndIf
         Next
         
         U_ITMsg(AllTrim(Str(nGravou))+" Produtos Gravados"+If(nGravou>0," Gravados com Sucesso.","."),'Atenção!',,2)

      EndIf
   
      Exit

   EndDo

Return

/*
1 - Potencial da carteira (Peso e valor): 
ZPP->ZPP_OK="LIBERADO" + ZPP->ZPP_OK="DESMARCADO"+ ZPP->ZPP_OK="REJEITADO" + ZPP->ZPP_OK="FALTAVOLUME" 

2 - Pedidos liberados (Peso e valor): 
ZPP->ZPP_OK="LIBERADO" + ZPP->ZPP_OK="REJEITADO"

3 - Pedidos não liberados (Peso e valor) com o motivo da não liberação Motivos:

3.1 - Falta de produto (vermelhos) //FALTA DE ESTOQUE
ZPP->ZPP_OK="FALTAESTOQUE"

3.2 - Falta de capacidade (Verdes com capacidade vermelho)
ZPP->ZPP_OK="FALTACAPACIDADE"

3.3 - Falta de formação de carga (Pedidos verdes apenas nas pastas das mesos)
ZPP->ZPP_OK="FALTAVOLUME"

3.4 - Decisão comercial (pedidos verdes nas pastas 1 e 2 que foram desmarcados)
ZPP->ZPP_OK="DESMARCADO"

*/
