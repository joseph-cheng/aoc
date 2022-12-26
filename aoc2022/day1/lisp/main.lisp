(defun parse (filename)
  (loop
    for x in (uiop:read-file-lines filename)
    with curr-list = (list)
    with result = (list)
    when (not (zerop (length x)))
      do (push (parse-integer x) curr-list)
    else
      do (push curr-list result) (setf curr-list (list))
    finally
       (return (push curr-list result)))
  )

(defun sums (l)
  (loop
    for x in l
    collect (loop for y in x sum y))
  )

(defun part1 (f)
  (car (sort (sums (parse f)) '>)))

(defun part2 (f)
  (let ((x (sort (sums (parse f)) '>)))
    (+ (nth 0 x) (nth 1 x) (nth 2 x))
    ))
