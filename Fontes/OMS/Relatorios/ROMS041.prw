/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
  Autor      |   Data   |                                             Motivo                                           
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich | 26/06/19 | Chamado 28886. Ajuste para loboguara.
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich | 27/06/19 | Chamado 29782. Ajuste de bug.
-------------------------------------------------------------------------------------------------------------------------------
Lucas Borges | 17/10/19 | Chamado 28346. Removidos os Warning na compilação da release 12.1.25. 
-------------------------------------------------------------------------------------------------------------------------------
Alex Wallauer| 24/06/24 | Chamado 47669. André. Correção do error.log array out of bounds [1] of [0]  Line : 454.
===============================================================================================================================
*/
//====================================================================================================
// Definicoes de Includes e Defines da Rotina.
//====================================================================================================
#Include "Totvs.Ch"
#Define _NTAMLINHA 54

/*
===============================================================================================================================
Programa----------: ROMS041
Autor-------------: Josué Danich Prestes
Data da Criacao---: 11/05/2016
===============================================================================================================================
Descrição---------: Emissão de capa de ocorrência de frete - Chamado 15345
===============================================================================================================================
Parametros--------: Nenhum
===============================================================================================================================
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function ROMS041()
Local _aCamposTab := {}
Local _lInverte := .F. 
Local _aButtons := {}, _lRet := .F.
//Local _aSizeAut  := MsAdvSize(.T.)
Local _bOk, _bCancel , _cTitulo


Private _aCampos := {}
Private _oMarkImp, _oDlg
Private _cMarca   := GetMark() 
Private _lMontaTela := .T.

Private _oReport	:= Nil
Private _aGrupos	:= {}
Private _ncolini 	:= 100
Private _ncolfim 	:= 2300

SET DATE FORMAT TO "DD/MM/YYYY"

Begin Sequence
   _cTitulo := "Lista de Ocorrências da Nota Fiscal: " +ZF5->ZF5_DOCOC+"-"+ZF5->ZF5_SEROC
  
   //================================================================================
   // Cria tabela temporária.
   //================================================================================                                    
   aAdd(_aCamposTab,{"WK_OK"     ,"C",2		                 ,0 })
   aAdd(_aCamposTab,{"ZF5_DOCOC" ,"C",TamSX3("ZF5_DOCOC")[1] ,0 })
   aAdd(_aCamposTab,{"ZF5_SEROC" ,"C",TamSX3("ZF5_SEROC")[1] ,0 })
   aAdd(_aCamposTab,{"ZF5_CODIGO","C",TamSX3("ZF5_CODIGO")[1],0 })
   aAdd(_aCamposTab,{"ZF5_MOTIVO","C",TamSX3("ZF5_MOTIVO")[1],0 })
   aAdd(_aCamposTab,{"WK_RECNO"  ,"N",10                     ,0 })
   
   aAdd(_aButtons,{"RESPONSA",{|| U_ROMS041M("T") },"Marc/Des","Marca/Desmarca Todos"})
       
   //================================================================================
   // Verifica se ja existe um arquivo com mesmo nome, se sim deleta.
   //================================================================================
   If Select("TRBZF5") > 0
      TRBZF5->( DBCloseArea() )
   EndIf

   //================================================================================
   // Permite o uso do arquivo criado dentro do protheus.
   //================================================================================
  _otemp := FWTemporaryTable():New( "TRBZF5", _aCamposTab )
   
   //================================================================================
   // Cria os indices para o arquivo.
   //================================================================================
   _otemp:AddIndex( "01", {"ZF5_CODIGO"} )

   _otemp:Create()
      
   //================================================================================
   // Carrega dados na tabela temporária.
   //================================================================================
   Processa( {|| _lRet := U_ROMS041D(ZF5->ZF5_DOCOC,ZF5->ZF5_SEROC) }, "Aguarde...", "Carregando as ocorrências da nota fiscal selecionada...",.F.)

   If !_lRet
      U_ITMsg("Não existem dados a serem exibidos.","Atenção",,1)
      Break
   EndIf
   
   //================================================================================
   // Monta colunas do MsSelect
   //================================================================================
                    //Campo         , "" , Titulo                                         , Picture   
   aAdd( _aCampos , { "WK_OK"		   , "" , ""                                             ,"@!"})
   aAdd( _aCampos , { "ZF5_DOCOC"	, "" , Posicione("SX3",2,"ZF5_DOCOC" ,"X3_TITULO")		, Posicione("SX3",2,"ZF5_DOCOC" ,"X3_PICTURE") } )
   aAdd( _aCampos , { "ZF5_SEROC"	, "" , Posicione("SX3",2,"ZF5_SEROC" ,"X3_TITULO")		, Posicione("SX3",2,"ZF5_SEROC" ,"X3_PICTURE") } )    
   aAdd( _aCampos , { "ZF5_CODIGO"	, "" , Posicione("SX3",2,"ZF5_CODIGO","X3_TITULO")		, Posicione("SX3",2,"ZF5_CODIGO","X3_PICTURE") } )
   aAdd( _aCampos , { "ZF5_MOTIVO"	, "" , Posicione("SX3",2,"ZF5_MOTIVO","X3_TITULO")		, Posicione("SX3",2,"ZF5_MOTIVO","X3_PICTURE")   } )
                                                                                                                                                    
   _bOk := {|| _lRet := .T., _oDlgImp:End()}
   _bCancel := {|| _lRet := .F., _oDlgImp:End()}

   While .T.
   _lRet:=.F.
   TRBZF5->(DBGoTop())
   //================================================================================
   // Monta a tela de dados com MSSELECT.
   //================================================================================      
   nAltura:=35
   Define MsDialog _oDlgImp Title _cTitulo From 0,0 To nAltura,80 Of oMainWnd 
      
      _oMarkImp:=MsSelect():New("TRBZF5","WK_OK","",_aCampos,@_lInverte, @_cMarca,{1,1,(_oDlgImp:nClientHeight-6)/2,(_oDlgImp:nClientWidth-4)/2})
      _oMarkImp:bMark := Eval({|| U_ROMS041M("P")})
      _lMontaTela := .F.
 
   Activate MsDialog _oDlgImp On Init (EnchoiceBar(_oDlgImp,_bOk,_bCancel,,_aButtons),;
                                     _oMarkImp:oBrowse:Align:=CONTROL_ALIGN_ALLCLIENT,;
                                     _oMarkImp:oBrowse:Refresh())

   If _lRet
      _lRet:=.F.
      TRBZF5->(DBGoTop()) 
      While ! TRBZF5->(Eof())
         If !Empty(TRBZF5->WK_OK)
            _lRet:=.T.
            Exit
         EndIf                        
         TRBZF5->(DBSkip())
      EndDo
      If _lRet
         Processa( {|| ROMS041P(  ) } , 'Aguarde!' , 'Imprimindo registros...' )
      Else
         U_ITMsg("Marque pelo menos um registro para continuar.","Atenção",'No botão "Outras Ações" tem a opção "Marca/Desmarca Todos" ',1)
         Loop
      EndIf
   EndIf
   
   Exit
   EndDo		
End Sequence

If Select("TRBZF5") > 0
   TRBZF5->(DBCloseArea())
EndIf

Return

/*
===============================================================================================================================
Programa--------: ROMS041D
Autor-----------: Julio de Paula Paz
Data da Criacao-: 30/05/2016
===============================================================================================================================
Descrição-------: Função para localizar todas as ocorrências para a nota fiscal selecionada e gravar na tabela temporária.
===============================================================================================================================
Parametros------: _cNumNF   = Numero da nota fiscal
                  _cSerieNF = Serie da nota fiscal
===============================================================================================================================
*/
User Function ROMS041D(_cNumNF,_cSerieNF  )
Local _aOrd := SaveOrd({"ZF5"})
Local _nRegAtu := ZF5->(Recno()) 
Local _lRet := .F.

Begin Sequence
   ZF5->(DBSetOrder(1)) //ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC 
   ZF5->(DBSeek(xFilial("ZF5")+_cNumNF+_cSerieNF))
   While ! ZF5->(Eof()) .And. ZF5->(ZF5_FILIAL+ZF5_DOCOC+ZF5_SEROC) == xFilial("ZF5")+_cNumNF+_cSerieNF
      TRBZF5->(DBAPPEND())
      TRBZF5->WK_OK      := _cMarca 
      TRBZF5->ZF5_DOCOC  := ZF5->ZF5_DOCOC
      TRBZF5->ZF5_SEROC  := ZF5->ZF5_SEROC
      TRBZF5->ZF5_CODIGO := ZF5->ZF5_CODIGO
      TRBZF5->ZF5_MOTIVO := ZF5->ZF5_MOTIVO 
      TRBZF5->WK_RECNO   := ZF5->(Recno()) 
      _lRet := .T.
      
      ZF5->(DBSkip())
   EndDo
   
End Sequence

RestOrd(_aOrd)
ZF5->(DBGoTo(_nRegAtu))

Return _lRet


/*
===============================================================================================================================
Programa--------: ROMS041M
Autor-----------: Julio de Paula Paz
Data da Criacao-: 30/05/2016
===============================================================================================================================
Descrição-------: Função para marcar e desmarcar todas as ocorrências da tabela temporária.
===============================================================================================================================
Parametros------: _cTipoMarca = "T" = Marca e desmarca todos os registros.
                  _cTipoMarca = "P" = Marca e desmarca apena o registro posisionado.
===============================================================================================================================
*/
User Function ROMS041M(_cTipoMarca)
Local _cSimboloMarca := Space(2)
Local _nRegAtu := TRBZF5->(Recno()) 

Begin Sequence          
   If _lMontaTela
      Break
   EndIf
   If Empty(TRBZF5->WK_OK )
      _cSimboloMarca := _cMarca
   Else
      _cSimboloMarca := Space(2)
   EndIf   
      
   If _cTipoMarca == "P"
      TRBZF5->WK_OK := _cSimboloMarca 
   Else
      TRBZF5->(DBGoTop())
      While ! TRBZF5->(Eof())
         TRBZF5->WK_OK := _cSimboloMarca 
         TRBZF5->(DBSkip())
      EndDo
   
   EndIf
           
End Sequence

TRBZF5->(DBGoTo(_nRegAtu)) 
_oMarkImp:oBrowse:Refresh()

Return

/*
===============================================================================================================================
Programa--------: ROMS041P
Autor-----------: Josué Danich Prestes
Data da Criacao-: 03/08/2015
===============================================================================================================================
Descrição-------: Função para controlar e imprimir os dados do relatório
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
*/
 
Static Function ROMS041P(  )

Local _cret := ""

Local _cNumNF, _cSerieNF, _cCTRC, _cTransport, _cCliente, _cVendedor, _cCoordenador
Local _cDataEntrega, _cDataChegada, _cPesoVeiculo, _cDataSaida
Local _nTotLinhas, _cTexto, _nI
Local _aOrd := SaveOrd({"SF2"})

Private _oPrint	:= Nil
Private _nLinha	:= 300
Private _oFont01	:= TFont():New( "Tahoma" ,, 24 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont02	:= TFont():New( "Tahoma" ,, 18 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont03	:= TFont():New( "Tahoma" ,, 14 , .F. , .F. ,, .T. ,, .T. , .F. )
Private _oFont03B	:= TFont():New( "Tahoma" ,, 14 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _oFont04	:= TFont():New( "Tahoma" ,, 12 , .F. , .T. ,, .T. ,, .T. , .F. )
Private _cTitulo := "Capa de ocorrência de frete"                  

Private _aObserv1 := {}, _aDtAbreOcorrencia := {}, _nVlCustoAdic, _nVlCustoClien, _nVlCustoItalac, _nVlCustoRepres, _nVlCustoTrans,_nVlCusto3,_nVlCustoE
Private _aMotivoOcor := {}, _aMotivoCusto := {}, _nVlCobradoTon, _aObserv2 := {}, _aStatusCusto := {} // , _aCalculoDesc :={}
Private _aServico := {}, _aNumOcorrencia := {} , _nValEmbFret

//====================================================================================================
// Numero e Serie da Nota Fiscal
//====================================================================================================
_cNumNF := ZF5->ZF5_DOCOC  // Numero da Nota fiscal
_cSerieNF := ZF5->ZF5_SEROC // Série da Nota Fiscal                                                   

//====================================================================================================
// Posiciona na tabela de notas fiscais de saída SF2.
//====================================================================================================
SF2->(DBSetOrder(1))
SF2->(DBSeek(xFilial("SF2")+_cNumNF+_cSerieNF))

//====================================================================================================
// Conhecimento de Transporte - CTRC
//====================================================================================================
_cCTRC := ZF5->ZF5_OBSFR // CTRC

//====================================================================================================
// Transportadora
//====================================================================================================
_cTransport := ZF5->ZF5_TRANSP + "/" + ZF5->ZF5_LJTRAN + " - " + ZF5->ZF5_NTRANS // Transportadora

//====================================================================================================
// Cliente
//====================================================================================================
If ! Empty(SF2->F2_CLIENTE)
   _cret := Posicione("SA1",1,xFilial("SA1")+SF2->(F2_CLIENTE+F2_LOJA),"A1_NREDUZ")          
   _cCliente :=  SF2->F2_CLIENTE+ "/" + SF2->F2_LOJA + " - " + AllTrim(_cret) // Cliente
Else
   _cCliente :=  ""
EndIf

//====================================================================================================
// Vendedor
//====================================================================================================    
If ! Empty(SF2->F2_VEND1)
   _cret := Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND1,"A3_NOME")
   _cVendedor := SF2->F2_VEND1 + " - " + AllTrim(_cret) // Vendedor
Else
   _cVendedor := ""
EndIf

//====================================================================================================
// Coordenador
//====================================================================================================
If ! Empty(SF2->F2_VEND2)
   _cret := Posicione("SA3",1,xFilial("SA3")+SF2->F2_VEND2,"A3_NOME")
   _cCoordenador := SF2->F2_VEND2 + " - " + AllTrim(_cret)
Else
   _cCoordenador := ""
EndIf                 

//====================================================================================================
// Data da Entrega
//====================================================================================================
_cDataEntrega := DToC(ZF5->ZF5_DATAE)

//====================================================================================================
// Data da Chegada
//====================================================================================================
_cDataChegada := DToC(ZF5->ZF5_DATAC) + " - " + ZF5->ZF5_HORAC 

//====================================================================================================
// Peso do Veículo
//====================================================================================================
If ! Empty(SF2->F2_CARGA)
   _cret := Posicione("DAK",1,xFilial("ZF5")+SF2->F2_CARGA,"DAK_PESO")
   _cPesoVeiculo := Transform(_cret, "@E 999,999,999.99")
Else
   _cPesoVeiculo := ""
EndIf
//====================================================================================================
// Data da Saída
//====================================================================================================
_cDataSaida := DToC(ZF5->ZF5_DATAS) + " - " + ZF5->ZF5_HORAS

//====================================================================================================
// Agrupa os dados das ocorrências que possuem o mesmo numero de nata fiscal.
//====================================================================================================
ROMS041A()

//====================================================================================================
// Inicializa o objeto do relatório
//====================================================================================================
_oPrint := TMSPrinter():New( _cTitulo )
_oPrint:Setup()
_oPrint:SetPortrait()
_oPrint:SetPaperSize(9)

//====================================================================================================
// Imprime ocorrências
//====================================================================================================

//====================================================================================================
// Inicializa a nova página e o posicionamento
//====================================================================================================
_oPrint:StartPage()
_nLinha	:= 280
	
//====================================================================================================
// Insere logo no cabecalho
//====================================================================================================
If File( "LGRL01.BMP" )
	_oPrint:SayBitmap( 050 , 050 , "LGRL01.BMP" , 410 , 170 )
EndIf
		
_oPrint:Say( 150 , _ncolini + 670 , "CHECK LIST DE CUSTO ADICIONAL   " 								, _oFont02 )
		
				
//====================================================================================================
// Adiciona cabecalho de conteúdo
//====================================================================================================
_nLinha := 280 //405
			
//====================================================================================================
// Impressão do Numero da Nota Fiscal
//====================================================================================================		
_oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Nota Fiscal: " 	, _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cNumNF +"-"+_cSerieNF	, _oFont03			)

ROMS041B() //Imprime box de campo
                                 
//====================================================================================================
// Impressão da Ocorrencia
//====================================================================================================
_cTexto := ""
For _nI := 1 To Len(_aNumOcorrencia)
    _cTexto += If(Empty(_cTexto),_aNumOcorrencia[_nI],"/"+_aNumOcorrencia[_nI]) 
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto.

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Ocorrência(s): " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next

//====================================================================================================
// Impressão do CTRC
//====================================================================================================
_nLinha += 90
_oPrint:Say(   _nLinha + 10,  _ncolini +  30, "CTRC : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cCTRC 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão da Transportadora
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Transportadora : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cTransport 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Cliente
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Cliente : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cCliente	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
//  Impressão do Vendedor
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Vendedor : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cVendedor   , _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Coordenador
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Coordenador : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cCoordenador   , _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Serviço
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "( "+_aServico[1]+" ) Descarga    ( "+_aServico[2]+" ) Deslocamento     ( "+_aServico[3]+" ) Diária      ( "+_aServico[4]+" ) Reentrega     ( "+_aServico[5]+"  ) Outros     " , _oFont03B			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão da Observação 1
//====================================================================================================
_cTexto := ""
_nTotLinhas := Len(_aNumOcorrencia)
 
For _nI := 1 To _nTotLinhas                            
    If !Empty(_aObserv1[_nI])
       If ! Empty(_cTexto)
          _cTexto += " / "
       EndIf
       _cTexto += If(_nTotLinhas > 1,AllTrim(_aNumOcorrencia[_nI])+"-","")+AllTrim(_aObserv1[_nI])
    EndIf
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto.
           
If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "OBS : " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next

//====================================================================================================
// Impressão da Data de Abertura da Ocorrencia
//====================================================================================================
_cTexto := ""
For _nI := 1 To Len(_aDtAbreOcorrencia)
    _cTexto += If(Empty(_cTexto),_aDtAbreOcorrencia[_nI]," - "+_aDtAbreOcorrencia[_nI]) 
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto.

If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Data abertura ocorrência : " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next

//====================================================================================================
// Impressão da Data de Entrega
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Data de Entrega : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cDataEntrega 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão da Data da Chegada
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Data da chegada : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cDataChegada 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão da Data da Saída do Cliente
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Data da Saída do Cliente : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cDataSaida 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Valor a Ressarcir ao transportador:
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor Total da Ocorrência: " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 950, transform(_nVlCustoAdic, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo
  
//====================================================================================================
// Impressão do valor de custo embutido no frete 
//====================================================================================================
_nLinha += 90   
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor Embutido no frete : " , _oFont03B			) 
_oPrint:Say(  _nLinha + 10,  _ncolini + 950, transform(_nVlCustoE, "@E 999,999,999.99") 	, _oFont03	)  

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Valor a Ressarcir ao transportador:
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Custo da Ocorrência: " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 950, transform(_nVlCustoAdic - _nVlCustoE, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo
  
//====================================================================================================
// Impressão do Valor de custo do cliente
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor do Custo Cliente : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 950, transform(_nVlCustoClien, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do valor de custo italac 
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor do Custo Italac : " , _oFont03B			)
_oPrint:Say(  _nLinha + 10,  _ncolini + 950, transform(_nVlCustoItalac, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do valor de custo do representante
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor do Custo Representante : " , _oFont03B			)
_oPrint:Say(  _nLinha + 10,  _ncolini + 950, transform(_nVlCustoRepres, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do valor de custo da transportadora 
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor do Custo Transportadora : " , _oFont03B			)
_oPrint:Say(  _nLinha + 10,  _ncolini + 950, transform(_nVlCustoTrans, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do valor de custo de terceiros
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor do Custo de Terceiros : " , _oFont03B			)
_oPrint:Say(  _nLinha + 10,  _ncolini + 950, transform(_nVlCusto3, "@E 999,999,999.99") 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão do Motivo do custo.
//====================================================================================================
_cTexto := ""  
_nTotLinhas := Len(_aNumOcorrencia)

For _nI := 1 To _nTotLinhas  
    If !Empty(_aMotivoCusto[_nI])
       If ! Empty(_cTexto)
          _cTexto += " / "
       EndIf
    
       _cTexto += If(_nTotLinhas > 1,AllTrim(_aNumOcorrencia[_nI])+"-","")+AllTrim(_aMotivoCusto[_nI])
    EndIf
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto. 
If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Motivo do custo : "            	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next


//====================================================================================================
// Motivo da Ocorrência 
//====================================================================================================
_cTexto := ""             
_nTotLinhas := Len(_aNumOcorrencia) 

For _nI := 1 To _nTotLinhas  
    If !Empty(_aMotivoOcor)
       If ! Empty(_cTexto)
          _cTexto += " / "
       EndIf
       _cTexto += If(_nTotLinhas > 1,AllTrim(_aNumOcorrencia[_nI])+"-","")+AllTrim(_aMotivoOcor[_nI])
    EndIf
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto. 
If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Motivo da Ocorrência : " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next

//====================================================================================================
// Impressão de Peso do Veículo
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Peso do veículo : " , _oFont03B			)
_oPrint:Say(   _nLinha + 10,  _ncolini + 700, _cPesoVeiculo 	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
//  Impressão do valor cobrado por tonelada.
//====================================================================================================
_nLinha += 90
_oPrint:Say(  _nLinha + 10,  _ncolini +  30, "Valor cobrado por tonelada : " , _oFont03B			)
_oPrint:Say(  _nLinha + 10,  _ncolini + 700, transform(_nVlCobradoTon, "@E 999,999,999.99")	, _oFont03			)

ROMS041B() //Imprime box de campo

//====================================================================================================
// Impressão das Observações
//====================================================================================================
_cTexto := ""    
_nTotLinhas := Len(_aNumOcorrencia)

For _nI := 1 To _nTotLinhas
    If !Empty(_aObserv2[_nI])
       If ! Empty(_cTexto)
          _cTexto += " / "
       EndIf

       _cTexto += If(_nTotLinhas > 1,AllTrim(_aNumOcorrencia[_nI])+"-","")+AllTrim(_aObserv2[_nI])
    EndIf
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto. 
If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf


For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Observações : " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next

//====================================================================================================
// Impressão do Status do Custo
//====================================================================================================
_cTexto := ""
_nTotLinhas := Len(_aNumOcorrencia)

For _nI := 1 To _nTotLinhas  
    If !Empty(_aStatusCusto[_nI])
       If ! Empty(_cTexto)
          _cTexto += " / "
       EndIf
    
       _cTexto += If(_nTotLinhas > 1,AllTrim(_aNumOcorrencia[_nI])+"-","")+AllTrim(_aStatusCusto[_nI])
    EndIf
Next                                                                        

_nTotLinhas := MlCount(_cTexto,_NTAMLINHA) // Conta o numero total de linhas de _cTexto.  
If _nTotLinhas > 3
   _nTotLinhas := 3 // Este limitador de linha é necessário para que o relatório ocupe apenas uma página.
EndIf

For _nI := 1 To _nTotLinhas
    _nLinha += 90
    
    If _nI == 1
       _oPrint:Say(   _nLinha + 10,  _ncolini + 30, "Status do custo : " 	, _oFont03B			)
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, 1 ) , _oFont03			)
       ROMS041B() //Imprime box de campo
    Else
       _oPrint:Say(   _nLinha + 10,  _ncolini + 700, MemoLine( _cTexto, _NTAMLINHA, _nI ) , _oFont03			)
       ROMS041B() //Imprime box de campo    
    EndIf
Next
                            
RestOrd(_aOrd) // Volta a ordem original dos indices do array _aOrd.

//=============================================================================
// Inicia o objeto de impressão                                              |
//=============================================================================
_oPrint:Preview()

Return

/*
===============================================================================================================================
Programa--------: ROMS041B
Autor-----------: Josué Danich Prestes
Data da Criacao-: 03/08/2015
===============================================================================================================================
Descrição-------: Imprime box de campos
===============================================================================================================================
Parametros------: Nenhum
===============================================================================================================================
*/
Static Function ROMS041B()

_oPrint:Line( _nLinha        , _ncolini              		 	, _nLinha        , _ncolfim		      )
_oPrint:Line( _nLinha + 0075 , _ncolini             			, _nLinha + 0075 , _ncolfim	          )
_oPrint:Line( _nLinha        , _ncolini              		 	, _nLinha + 0075 , _ncolini           )
_oPrint:Line( _nLinha        , _ncolfim	       		 		    , _nLinha + 0075 , _ncolfim	          )

Return

/*
===============================================================================================================================
Programa--------: ROMS041A
Autor-----------: Julio de Paula Paz
Data da Criacao-: 25/05/2016
===============================================================================================================================
Descrição-------: Agrupa os dados das ocorrências.
===============================================================================================================================
Parametros------: 
===============================================================================================================================
*/
Static Function ROMS041A()
Local _aOrd := SaveOrd({"ZF5","TRBZF5"})
Local _nRegAtu := TRBZF5->(Recno()) 
Local _cDescarga, _cDeslocamento, _cDiária, _cReentrega, _cOutros  
 
Begin Sequence   
   _nVlCustoAdic   := 0
   _nVlCustoClien  := 0
   _nVlCusto3      := 0
   _nVlCustoE      := 0
   _nVlCustoItalac := 0
   _nVlCustoRepres := 0 
   _nVlCustoTrans  := 0
   _nVlCobradoTon  := 0
   _cDescarga      := Space(1)
   _cDeslocamento  := Space(1)
   _cDiária        := Space(1)
   _cReentrega     := Space(1)
   _cOutros        := Space(1)
   
   TRBZF5->(DBGoTop()) 
   
   While ! TRBZF5->(Eof())
      If Empty(TRBZF5->WK_OK)
         TRBZF5->(DBSkip())
         Loop
      EndIf                        
      
      ZF5->(DBGoTo(TRBZF5->WK_RECNO))
      _nVlCustoAdic   += ZF5->ZF5_CUSTO 
      _nVlCustoClien  += ZF5->ZF5_CUSTOC
      _nVlCustoItalac += ZF5->ZF5_CUSTOI
      _nVlCustoRepres += ZF5->ZF5_CUSTOR
      _nVlCustoTrans  += ZF5->ZF5_CUSTOT 
      _nVlCusto3  	  += ZF5->ZF5_CUSTER
      _nVlCustoE  	  += ZF5->ZF5_VALEMB
      
      _nVlCobradoTon  += ZF5->ZF5_VALTON 
   
      
      aAdd(_aNumOcorrencia,AllTrim(ZF5->ZF5_CODIGO))
      aAdd(_aObserv1,AllTrim(ZF5->ZF5_OBSCT))
      aAdd(_aDtAbreOcorrencia,DToC(ZF5->ZF5_DTINI))
      aAdd(_aMotivoOcor, AllTrim(ZF5->ZF5_MOTIVO))
      aAdd(_aMotivoCusto, AllTrim(ZF5->ZF5_MOTCUS))

      aAdd(_aObserv2, AllTrim(ZF5->ZF5_OBS))
      _cStatusCusto := IIf(ZF5->ZF5_STATC = "P", "Pendente",	IIf(ZF5->ZF5_STATC = "E", "Encerrado",IIf(ZF5->ZF5_STATC = "T", "Em tratamento","")))
      aAdd(_aStatusCusto, _cStatusCusto) 

      If ZF5->ZF5_SERVIC == '1'     // Descarga
         _cDescarga      := "X"
      ElseIf ZF5->ZF5_SERVIC == '2' // Deslocamento
         _cDeslocamento  := "X"
      ElseIf ZF5->ZF5_SERVIC == '3' // Diária
         _cDiária        := "X"
      ElseIf ZF5->ZF5_SERVIC == '4' // Reentrega
         _cReentrega     := "X"
      ElseIf ZF5->ZF5_SERVIC == '5' // Outros
         _cOutros        := "X"
      EndIf
      _aServico := {_cDescarga, _cDeslocamento, _cDiária, _cReentrega, _cOutros}
                                                                                                                
      TRBZF5->(DBSkip())
   EndDo   
   
End Sequence

RestOrd(_aOrd)
ZF5->(DBGoTo(_nRegAtu ))

Return
