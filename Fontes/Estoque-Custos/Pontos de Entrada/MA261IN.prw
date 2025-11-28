/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
André Lisboa  |12/03/2024| Chamado 46558 - Alteração na exibição campos motivo transf/descr transf/ incluido campo setor.
Julio Paz     |16/05/2024| Chamado 46558 - Desenvolvimento de Melhorias na rotina de transferência de produtos.
Lucas Borges  |19/09/2025| Chamado 50617. Migração dos parâmetros da ZP1 para SX6
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MA261IN
Autor-------------: Talita Teixeira
Data da Criacao---: 06/06/2013 
Descrição---------: Ponto de entrada responsavel em atribuir valores ao aCols para campos customizados. Está dentor de um 
                    While sobre os resgistros da tabela SD3.	
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================*/
User Function MA261IN( )

Local _cPosCampo 	:= aScan(aHeader, {|x| AllTrim(Upper(x[2]))=='D3_I_OBS'})
Local _ntptrs   // 	:= aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="D3_I_TPTRS"})
Local _nPosNumSeq	:= aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="D3_NUMSEQ"})
Local _aareasd3 	:= SD3->(GetArea())
Local _nDsctptrs  // := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCTM"})
Local _nSetor		:= aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="D3_I_SETOR"})
Local _nDesti		:= aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="D3_I_DESTI"})
Local _cDadoCBox 
Local _nMotTrRef  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_MOTTR"})
Local _nDscMTrRf  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCMT"})
Local _cFilVld34  := SuperGetMV('IT_FILVLD3',.F.,'')

If ! xFilial("SD3") $ _cFilVld34 
   _ntptrs     := aScan(aHeader, {|x| AllTrim(Upper(x[2]))=="D3_I_TPTRS"}) // Este campo não deve ser considerado quando as validações do Armazém 34 (Descarte) estiver habilitada.
   _nDsctptrs  := aScan(aHeader,{|x|AllTrim(Upper(x[2]))=="D3_I_DSCTM"})
EndIf 

If !Inclui		
	SD3->(DBSeek( _cSeek := xFilial('SD3')+cDocumento,.F.))

	While !SD3->(Eof()) .And. _cSeek == SD3->D3_FILIAL+SD3->D3_DOC
	    If SD3->D3_NUMSEQ == aCols[Len(aCols),_nPosNumSeq] .And. SD3->D3_CF == 'RE4' 
	    	aCols[Len(aCols),_cPosCampo]:= SD3->D3_I_OBS
			If ! xFilial("SD3") $ _cFilVld34 
	    	   aCols[Len(aCols),_ntptrs]   := SD3->D3_I_TPTRS
			EndIf 

            If xFilial("SD3") $ _cFilVld34 
			   aCols[Len(aCols),_nSetor]   := SD3->D3_I_SETOR
			   aCols[Len(aCols),_nDesti]   := SD3->D3_I_DESTI
               //-------------
               aCols[Len(aCols),_nMotTrRef] := SD3->D3_I_MOTTR
			   aCols[Len(aCols),_nDscMTrRf] := SD3->D3_I_DSCMT
			EndIf 

            //-------------
            If ! xFilial("SD3") $ _cFilVld34 
               If ! Empty(SD3->D3_I_TPTRS)
			      _cDadoCBox := X3CBoxDesc("D3_I_TPTRS",SD3->D3_I_TPTRS)
                  aCols[Len(aCols),_nDsctptrs] := Posicione("SF5",1,xFilial("SF5")+U_ITKEY(_cDadoCBox,"F5_CODIGO"),"F5_TEXTO")
			   Else
                  aCols[Len(aCols),_nDsctptrs] := ""
			   EndIf 
               
			   If ! Empty(SD3->D3_I_TPTRS)
                 aCols[Len(aCols),_nDsctptrs] := Posicione("CYO",1,xFilial("CYO")+aCols[Len(aCols),_ntptrs],"CYO_DSRF")
			   Else
                  aCols[Len(aCols),_nDsctptrs] := ""
			   EndIf 
            EndIf

	    	Exit
	    EndIf
		SD3->(DBSkip())
	EndDo
EndIf

SD3->(FWRestArea(_aareasd3))

Return
