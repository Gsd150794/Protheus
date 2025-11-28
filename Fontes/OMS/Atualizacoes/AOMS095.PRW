/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
       Autor      |    Data    |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich      | 10/06/2019 | Ajuste para loboguara - Chamado 29593
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges      | 14/10/2019 | Removidos os Warning na compilação da release 12.1.25. Chamado 28346
===============================================================================================================================
*/

//====================================================================================================
// Definicoes de Includes da Rotina.
//====================================================================================================
#Include "TOTVS.ch"
#Include "APWEBSRV.CH"

/*
===============================================================================================================================
Programa----------: AOMS095
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/03/2017
===============================================================================================================================
Descrição---------: Rotina de visualização dos dados das tabelas de muro da integração de liberação financeiro do CTE
                    via webservice do sistema RDC.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS095()
Local _aCores := {}
Private aRotina := {}
Private cCadastro 

Begin Sequence
   cCadastro := "Consulta dos dados de Integração de Liberação Financeiro CTE Via Webservice: Italac <---> RDC"
   aAdd(aRotina,{"Pesquisar"              ,"AxPesqui"   ,0,1})
   aAdd(aRotina,{"Visualizar"             ,"U_AOMS095V" ,0,2})   
   aAdd(aRotina,{"Legenda"                ,"U_AOMS095L" ,0,6})
   
   aAdd(_aCores,{"ZG7_SITUAC == 'N'" ,"BR_VERDE" })
   aAdd(_aCores,{"ZG7_SITUAC == 'P'" ,"BR_VERMELHO" })
   aAdd(_aCores,{"ZG7_SITUAC == 'R'" ,"BR_AMARELO" })

   DBSelectArea("ZG7")
   ZG7->(DBSetOrder(1)) 
   ZG7->(DBGoTop())
   MBrowse(6,1,22,75,"ZG7", , , , , , _aCores)
   
End Sequence

Return    

/*
===============================================================================================================================
Função------------: AOMS095L
Autor-------------: Julio de Paula Paz
Data da Criacao---: 27/03/2017
===============================================================================================================================
Descrição---------: Rotina de Exibição da Legenda do MBrowse.
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/  
User Function AOMS095L()       
Local _aLegenda := {}

Begin Sequence                                                                           
   aAdd(_aLegenda,{"BR_VERDE"    ,"Não Processado" })
   aAdd(_aLegenda,{"BR_AMARELO"  ,"Rejeitada" })
   aAdd(_aLegenda,{"BR_VERMELHO" ,"Processado" })

   BrwLegenda(cCadastro, "Legenda", _aLegenda)

End Sequence

Return

/*
=================================================================================================================================
Programa--------: AOMS095V()
Autor-----------: Julio de Paula Paz
Data da Criacao-: 27/03/2017
=================================================================================================================================
Descrição-------: Exibe os dados da liberação Financeiro CTE do registro posicionado na tela do MsBrowse.
=================================================================================================================================
Parametros------: Nenhum
=================================================================================================================================
Retorno---------: Nenhum
=================================================================================================================================
*/
User Function AOMS095V()
Local _aStrucZG8
Local _aCmpZG8 := {}
Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo
Local _lInvZG8 := .F.
Local _oDlgEnch, _nI
Local _nReg := 2 , _nOpcx := 2
Local _nni	:= 0

Private _oMarkZG8, _cMarcaZG8 := GetMark() 

Begin Sequence     
   //================================================================================
   // Cria as estruturas das tabelas temporárias
   //================================================================================
   _aStrucZG8 := ZG8->(DbStruct())

    //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim fecha.
   //================================================================================
   If Select("TRBZG8") > 0
      TRBZG8->( DBCloseArea() )
   EndIf
      
   _otemp := FWTemporaryTable():New( "TRBZG8", _aStrucZG8 )

   _oTemp:AddIndex( "01", {"ZG8_CHVCTE"} )

   _otemp:Create()
    
   //================================================================================
   // Monta as colunas do MSSELECT para a tabela temporária TRBZG8 
   //================================================================================
   _astruct := ZG8->(Dbstruct())
   For _nni := 1 to Len(_astruct)
      If AllTrim(_astruc[_nni][1])=="ZG8_FILIAL"
          Loop
      EndIf
      aAdd( _aCmpZG8 , { AllTrim(_astruc[_nni][1]),;
                         "" ,;
                         Getsx3cache(AllTrim(_astruc[_nni][1]),"X3_TITULO"),;
                         Getsx3cache(AllTrim(_astruc[_nni][1]),"SX3->X3_PICTURE") } )
   Next                                                                                  
   //================================================================================
   // Carrega os dados da tabela ZG7
   //================================================================================
   For _nI := 1 To ZG7->(FCount())
       &("M->"+ZG7->(FieldName(_nI))) :=  &("ZG7->"+ZG7->(FieldName(_nI)))
   Next
   
   //================================================================================
   // Carrega os dados da tabela ZG8
   //================================================================================
   ZG8->(DBSetOrder(4))  // ZG8_FILIAL+ZG8_FATURA+ZG8_CNPJTR+ZG8_SITUAC
   ZG8->(DBSeek(ZG7->(ZG7_FILIAL+ZG7_FATURA+ZG7_CNPJTR+ZG7_SITUAC)))
   While ! ZG8->(Eof()) .And. ZG8->(ZG8_FILIAL+ZG8_FATURA+ZG8_CNPJTR+ZG8_SITUAC) == ZG7->(ZG7_FILIAL+ZG7_FATURA+ZG7_CNPJTR+ZG7_SITUAC)
      If ZG8->ZG8_REGCAP <> ZG7->ZG7_REGCAP
         ZG8->(DBSkip())
         Loop
      EndIf
      
      TRBZG8->(RecLock("TRBZG8",.T.))
      For _nI := 1 To TRBZG8->(FCount())
          &("TRBZG8->"+TRBZG8->(FieldName(_nI))) :=  &("ZG8->"+ZG8->(FieldName(_nI)))
      Next
      TRBZG8->(MSUnLock())
      
      ZG8->(DBSkip())
   EndDo
   TRBZG8->(DBGoTop())
                                       
   //================================================================================
   // Monta a tela Enchoice ZG7  x MsSelect ZG8
   //================================================================================    
   _aObjects := {} 
   aAdd( _aObjects, { 315,  50, .T., .T. } )
   aAdd( _aObjects, { 100, 100, .T., .T. } )

   _aInfo := { _aSizeAut[ 1 ], _aSizeAut[ 2 ], _aSizeAut[ 3 ], _aSizeAut[ 4 ], 3, 3 } 

   _aPosObj := MsObjSize( _aInfo, _aObjects, .T. ) 
   
   _bOk := {|| _oDlgEnch:End()}
   _bCancel := {|| _lRet := .F., _oDlgEnch:End()}
                       
   _cTitulo := "Integração de Liberação Financeiro CTE Via WebService - Visualização"
   
   Define MsDialog _oDlgEnch Title _cTitulo From _aSizeAut[7],00 To _aSizeAut[6], _aSizeAut[5] Of oMainWnd Pixel 
      
      EnChoice( "ZG7" ,_nReg, _nOpcx, , , , , _aPosObj[1], , 3 )
            
      _oMarkZG8 := MsSelect():New("TRBZG8","","",_aCmpZG8,@_lInvZG8, @_cMarcaZG8,{_aPosObj[2,1], _aPosObj[2,2], _aPosObj[2,3], _aPosObj[2,4]})
        
   Activate MsDialog _oDlgEnch On Init EnchoiceBar(_oDlgEnch,_bOk,_bCancel) 

End Sequence

//================================================================================
// Fecha e exclui as tabelas temporárias
//================================================================================                    
If Select("TRBZG8") > 0
   (TRBZG8)->(DBCloseArea())
EndIf

Return
