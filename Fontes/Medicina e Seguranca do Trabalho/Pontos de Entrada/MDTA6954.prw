/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Danich  |31/08/2018| Chamado 25248. Controle de processamento paralelo.
Lucas Borges  |02/10/2019| Chamado 28346. Removidos os Warning na compilação da release 12.1.25.
Alex Wallauer |05/02/2024| Chamado 46134. Retirada a chamada da funcao de validacao MDTA6954P(oproc).
===============================================================================================================================
*/

#Include "TOTVS.ch"

Static _lDevAlmox := .F. // Indica que a rotina foi ou não chamada da função customizada Dev.Almox.
Static _aRecnosEPIs := {}  // Array para armazenar os Recnos de EPIs que deverãoser impressos.

/*
===============================================================================================================================
Programa----------: MDTA6954
Autor-------------: Darcio Ribeiro Spörl
Data da Criacao---: 14/06/2016
Descrição---------: Ponto de Entrada executado como última validação e gravações específicas - Chamado 15889
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDTA6954()

Local _aArea	:= FWGetArea()
Local _cMatric	:= SRA->RA_MAT
Local _nPosEpi	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_CODEPI"	})
Local _nPosFor	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_FORNEC"	})
Local _nPosLoj	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_LOJA"	})
Local _nPosCap	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_NUMCAP"	})
Local _nPosDte	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_DTENTR"	})
Local _nPosHre	:= aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_HRENTR"	})
Local _nPosBmp	:= aScan(aHeader,{|x| AllTrim(x[2]) == "COLBMP"		})
Local _nPosQtdDev := aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_QTDEVO"}) 
Local _nPosDtRec := aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_DTRECI"})  
Local _lRet := .T.
Local _nRegAtu := TNF->(Recno())
Local _nI 

DBSelectArea("TNF")
TNF->(DBSetOrder(1)) // TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR                                                                        
If TNF->(DBSeek(xFilial("TNF") + aCols[n][_nPosFor] + aCols[n][_nPosLoj] + aCols[n][_nPosEpi] + aCols[n][_nPosCap] + _cMatric + DToS(aCols[n][_nPosDte]) + aCols[n][_nPosHre]))
   If TNF->TNF_I_TPDV == "S" .And. TNF->TNF_QTDENT == TNF->TNF_QTDEVO .And. aCols[n][_nPosBmp] == "BR_VERMELHO"
      RecLock("TNF",.F.)
      TNF->TNF_I_TPDV := "N"
      TNF->(MSUnLock())
   Else        
      If ! _lDevAlmox        //IsInCallStack("MDT695DVPA") // "NG695TudOk"
         If TNF->TNF_I_TPDV = 'T' .Or. TNF->TNF_I_TPDV = 'R' // Pela rotina padrão de devolução de EPIs, devolução parcial, não há baixa de estoques.
	        RecLock("TNF",.F.)
	        TNF->TNF_I_TPDV := " " 
	        TNF->(MSUnLock())
	     EndIf
	  EndIf
   EndIf
EndIf

//================================================================================
// Carrega array ADevEPI com os registros que deveão ter o recibo impresso.
//================================================================================
_aRecnosEPIs := {}

For _nI := 1 To Len(aCols)
    // TNF_FILIAL+TNF_FORNEC+TNF_LOJA+TNF_CODEPI+TNF_NUMCAP+TNF_MAT+DToS(TNF_DTENTR)+TNF_HRENTR                                                                        
    If TNF->(DBSeek(xFilial("TNF") + aCols[_nI][_nPosFor] + aCols[_nI][_nPosLoj] + aCols[_nI][_nPosEpi] + aCols[_nI][_nPosCap] + _cMatric + DToS(aCols[_nI][_nPosDte]) + aCols[_nI][_nPosHre]))
       _nPosQtdDev := aScan(aHeader,{|x| AllTrim(x[2]) == "TNF_QTDEVO"})   
              
       If aCols[_nI,_nPosQtdDev] <> TNF->TNF_QTDEVO .And. !Empty(aCols[_nI,_nPosDtRec]) // TNF->TNF_DTRECI
          aAdd(ADevEPI,TNF->(Recno()))
          aAdd(_aRecnosEPIs,TNF->(Recno()))
       EndIf
    EndIf
Next _nI

//================================================================================
// Carrega o array ADevEPI com os EPIs liberados na rotina de estoques e custos.
//================================================================================
TNF->(DBSetOrder(3)) // TNF_FILIAL+TNF_MAT+TNF_CODEPI+DToS(TNF_DTENTR)+TNF_HRENTR                                                                                                       
TNF->(DBSeek(xFilial("TNF")+M->RA_MAT))
   
While !TNF->(Eof()) .And. TNF->TNF_FILIAL+TNF->TNF_MAT == xFilial("TNF")+M->RA_MAT
      
   If TNF->TNF_I_IMPR == "1" // Sim
      aAdd(ADevEPI,TNF->(Recno()))
      aAdd(_aRecnosEPIs,TNF->(Recno()))
      
      TNF->(RecLock("TNF",.F.))
      TNF->TNF_I_IMPR := "2" // Não
      TNF->(MSUnLock())
   EndIf
      
   TNF->(DBSkip())
EndDo

TNF->(DBGoTo(_nRegAtu))

FWRestArea(_aArea)
Return _lRet

/*
===============================================================================================================================
Programa----------: MDT6954G
Autor-------------: Julio de Paula Paz
Data da Criacao---: 31/10/2017
Descrição---------: Muda conteúdo de variável estática para indicar se a rotina Customizada Dev.Almox. foi acionada ou não.
Parametros--------: _lValStatic = Valor do conteúdo da variável estática.(.T. = True / .F. = False)
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MDT6954G(_lValStatic)

Begin Sequence
   _lDevAlmox := _lValStatic
End Sequence

Return

/*
===============================================================================================================================
Programa----------: MDT6954H
Autor-------------: Julio de Paula Paz
Data da Criacao---: 14/11/2017
Descrição---------: Zerar ou retornar o conteúdo da variável estática _aRecnosEPIs.
Parametros--------: _cTipoFunc = Tipo de funcionalidade da rotina (Zerar ou retornar o conteúdo da variávStaticatica
                                 _aRecnosEPIs).
Retorno-----------: _nRet = Retorna o conteúdo da variávStaticatica _aRecnosEPIs
===============================================================================================================================
*/
User Function MDT6954H(_cTipoFunc)

Local _aRet := {}

Begin Sequence
   If _cTipoFunc == "INICIALIZA"
      _aRecnosEPIs := {}
   Else
      _aRet := AClone(_aRecnosEPIs)
   EndIf

End Sequence

Return _aRet
