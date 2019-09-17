;*************Fonction pour générer un profil en travers****************;
(defun c:ptt (/ lst lst0 pt0 pt1 pt2 pt osmode dist z ins calqueCST calqueTN calqueTBL diff tmp lip nb)

  ;*********************GESTION DES CALQUES**********************;
  (setq calqueCST "PTT_Construct")
  (if (not (tblsearch "LAYER" calqueCST)) (command "._layer" "_M" calqueCST "_C" 210 "" ""))
  (setq calqueTN "PTT_TN")
  (if (not (tblsearch "LAYER" calqueTN)) (command "._layer" "_M" calqueTN "_C" 92 "" ""))
  (setq calqueTBL "PTT_Tableau")
  (if (not (tblsearch "LAYER" calqueTBL)) (command "._layer" "_M" calqueTBL "_C" 250 "" ""))
  (setq calqueProfil "PTT_Profil")
  (if (not (tblsearch "LAYER" calqueProfil)) (command "._layer" "_M" calqueProfil "_C" 10 "" "_lw" 0.2 "" ""))
  (activeLayer calqueProfil)

  ;*****************GESTION DU STYLE DE TEXTE********************;
  (setq oldstyle (getvar "textstyle"))
  (command "._Style" "PTT_lsp" "arial.ttf" 0.4 1 0 "N" "N")

  ;*****************GESTION DU TYPE DE LIGNE*********************;
  (command "_.LINETYPE" "A" "Continuous" "" "")

  ;************************Ligne de PTT**************************;
  (setq Pt1 (getpoint "\Point1: "))
  (setq Pt2 (getpoint "\Point2: "))
  (command "_pline" "_non" Pt1 "_non" Pt2 "_wi" 0 "" "")
  (command "_text" "_non" Pt1 0 (getstring "\Numero profil") "" "")
  (activeLayer calqueCST)  

  ;**********Création de la liste des informations***************;
  (setq lst '(0))
  (setq osmode (getvar "OSMODE"))
  (setvar "OSMODE" 128)
  (while (setq pt0 (getpoint "\nSélectionner un point: "))
    (setq pt4 (perpDraw pt0 pt1 pt2))
    (command "_pline" "_non" pt0 "_non" pt4 "" "")
    (setq pt pt0)
    (if (= (car lst) 0)
      (setq dist (list 0.0))
      (setq dist (list (distance (point2D pt4) (point2D (last lst))))) )
    (debugMsg "pt4" (point2D pt4))
    (debugMsg "pt lst" (last lst))
    (debugMsg "Dist" dist)
    (setq z (list (getreal "\nSaisir Z: ")))
    (if (= (car lst) 0)
      (setq lst (list (append pt dist z)))
      (setq lst (append lst (list (append pt dist z)))) ) )
  (setvar "OSMODE" osmode)
  (setq lst0 lst)
  (print lst0)

  ;**************Choix de la zone de tracage********************;
  (setq ins (getpoint "\nChoisir le point d'insertion: "))

  ;*********************GESTION DES CALQUES**********************;
  (activeLayer calqueTN)  

  ;**************************Tracage du TN***********************;
  (setq cumulDst 0)
  (foreach x (cdr lst)
    (setq cumulDst (+ cumulDst (cadr (cddr x))))
    (setq tmp
	   (append tmp
		   (list
		     (list
		       (+ (car ins) cumulDst)
		       (+ (- (cadr (cdddr x)) (cadr (cdddr (car lst0)))) (cadr ins))
		       0.0 )
		     )
		   )
	  )
    )
  (setq lst (append (list ins) tmp))
  (command "_pline" (foreach pt lst (command "_non" pt)) "")

  ;***********************Présentation du PTT******************;
  ;;Création lignes verticales
  (setq lip (- (cadr ins) (+ (diffY lst) 7)))
  (foreach pt lst (command "_pline" "_non" pt "_non" (list (car pt) lip 0.0) ""))
  ;;Tableau
  (activeLayer calqueTBL)
  (setq firstCase 7)
  (setq lastCase 3)
  (setq lignes '("Distance partielles Projet" "Distance axe Projet" "Altitudes Projet" "Distance partielles TN" "Distance axe TN" "Altitude TN" ""))
  (setq nb 0)
  (print lst0)
  (foreach ligne lignes
    (command "_pline" "_non" (list (- (caar lst) firstCase) (+ lip nb) 0.0) "_non" (list (+ (car (last lst)) lastCase) (+ lip nb) 0.0) "")(setq nb (+ nb 1))
    (command "_text" "_non" (list (- (caar lst) (- firstCase 0.3)) (+ lip (- nb 0.8)) 0.0) 100 ligne "" "")
    (cond
	  ((= ligne "Altitude TN")
		(setq nb2 0)
		(foreach pt lst0	     
			   (command "_text" "_non" (list (+ (car (nth nb2 lst)) 0.3) (+ lip (- nb 0.8)) 0.0) 100 (rtos (caddr (cddr pt)) 2 2) "" "")
		  	   (setq nb2 (+ nb2 1)) ) )
	  ((= ligne "Distance partielles TN") (foreach pt lst
			   (command "_text" "_non" (list (+ (car pt) 0.3) (+ lip (- nb 0.8)) 0.0) 100 (rtos (- (car pt) (car ins)) 2 2) "" "") )) ) )	  
  (command "_pline" "_non" (list (- (caar lst) firstCase) lip 0.0)  "_non" (list (- (caar lst) firstCase) (+ lip (- (length lignes) 1)) 0.0) "")
  (command "_pline" "_non" (list (+ (car (last lst)) lastCase) lip 0.0)  "_non" (list (+ (car (last lst)) lastCase) (+ lip (- (length lignes) 1)) 0.0) "")

  ;*******************************Style fin***********************;
  (setvar "textstyle" oldstyle)
  (command "._layer" "_OFF" calqueCST "" "")
  
  ;**************************Sortie de programme***************;
  (princ) )



;*********************FONCTIONS EXTERNES************************;
(defun smaller (liste)
  (setq nb (car liste))
  (foreach elem liste (if (< elem nb) (setq nb elem)))
  nb )

(defun higter (liste)
  (setq nb (car liste))
  (foreach elem liste (if (> elem nb) (setq nb elem)))
  nb )

(defun diffY (liste)
  (setq tmp '())
  (foreach pt liste (setq tmp (append tmp (list (cadr pt)))))
  (setq result (- (cadar liste) (smaller tmp)))
  result )

(defun point2D (liste)
  (setq result (list (nth 0 liste) (nth 1 liste) (nth 2 liste)))
  result )

(defun activeLayer (layer)
  (command "._layer" "_S" layer "")
  (princ) )

(defun perpDraw (pt0 pt1 pt2)
  (setq Ang1 (atan (/ (- (car pt2) (car pt1)) (- (cadr pt2) (cadr pt1)))))
  (debugMsg "Ang1" Ang1)
  (setq result (inters pt1 pt2 pt0 (polar pt0 (+ (/ pi 2) (angle pt1 pt2)) 1) nil))
  (debugMsg "Result" result)
  result )

(defun debugMsg (txt var)
  (print (strcat txt " : "))(prin1 var) )