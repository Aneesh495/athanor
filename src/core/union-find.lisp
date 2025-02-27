;;;; union-find.lisp - Disjoint-Set Forest with Path Compression and Rank Balancing

(in-package #:athanor)

(defstruct (union-find (:constructor %make-union-find))
  "Disjoint-set forest data structure with rank balancing and path compression."
  (parents (make-array 1024 :element-type 'e-id :adjustable t :fill-pointer 0)
   :type (vector e-id))
  (ranks (make-array 1024 :element-type '(unsigned-byte 16) :adjustable t :fill-pointer 0)
   :type (vector (unsigned-byte 16)))
  (sizes (make-array 1024 :element-type 'fixnum :adjustable t :fill-pointer 0)
   :type (vector fixnum))
  (set-count 0 :type fixnum))

(defun make-union-find (&optional (initial-capacity 1024))
  "Allocate an empty union-find disjoint-set forest with given initial capacity."
  (let ((parents (make-array initial-capacity :element-type 'e-id :adjustable t :fill-pointer 0))
        (ranks (make-array initial-capacity :element-type '(unsigned-byte 16) :adjustable t :fill-pointer 0))
        (sizes (make-array initial-capacity :element-type 'fixnum :adjustable t :fill-pointer 0)))
    (%make-union-find :parents parents :ranks ranks :sizes sizes :set-count 0)))

(defun uf-make-set (uf)
  "Create a new singleton set in the forest, returning its allocated e-id."
  (declare (type union-find uf))
  (let* ((parents (union-find-parents uf))
         (ranks (union-find-ranks uf))
         (sizes (union-find-sizes uf))
         (new-id (fill-pointer parents)))
    (vector-push-extend new-id parents)
    (vector-push-extend 0 ranks)
    (vector-push-extend 1 sizes)
    (incf (union-find-set-count uf))
    new-id))

(defun uf-find (uf id)
  "Find the representative root of the set containing ID with two-pass path compression."
  (declare (type union-find uf)
           (type e-id id)
           (optimize (speed 3) (safety 1)))
  (let ((parents (union-find-parents uf)))
    ;; Step 1: Traverse upward to locate the canonical root
    (let ((root id))
      (loop while (/= root (aref parents root))
            do (setf root (aref parents root)))
      ;; Step 2: Compress path by linking all visited nodes directly to the root
      (let ((curr id))
        (loop while (/= curr root)
              do (let ((parent (aref parents curr)))
                   (setf (aref parents curr) root)
                   (setf curr parent))))
      root)))

(defun uf-union (uf id1 id2)
  "Merge the sets containing ID1 and ID2 using union-by-rank.
   Returns the canonical root of the merged set.
   If ID1 and ID2 are already in the same set, returns that root without modification."
  (declare (type union-find uf)
           (type e-id id1 id2)
           (optimize (speed 3) (safety 1)))
  (let ((root1 (uf-find uf id1))
        (root2 (uf-find uf id2)))
    (if (= root1 root2)
        root1
        (let ((ranks (union-find-ranks uf))
              (parents (union-find-parents uf))
              (sizes (union-find-sizes uf)))
          (decf (union-find-set-count uf))
          (let ((rank1 (aref ranks root1))
                (rank2 (aref ranks root2)))
            (cond
              ((< rank1 rank2)
               (setf (aref parents root1) root2)
               (incf (aref sizes root2) (aref sizes root1))
               root2)
              ((> rank1 rank2)
               (setf (aref parents root2) root1)
               (incf (aref sizes root1) (aref sizes root2))
               root1)
              (t
               ;; Equal ranks: arbitrarily attach root2 to root1 and increment rank1
               (setf (aref parents root2) root1)
               (incf (aref ranks root1))
               (incf (aref sizes root1) (aref sizes root2))
               root1)))))))

(defun uf-connected-p (uf id1 id2)
  "Return T if ID1 and ID2 belong to the same equivalence class, NIL otherwise."
  (declare (type union-find uf)
           (type e-id id1 id2))
  (= (uf-find uf id1) (uf-find uf id2)))

(defun uf-count (uf)
  "Return total number of elements allocated in the union-find structure."
  (fill-pointer (union-find-parents uf)))

(defun uf-set-size (uf id)
  "Return the cardinality of the equivalence class containing ID."
  (declare (type union-find uf)
           (type e-id id))
  (let ((root (uf-find uf id)))
    (aref (union-find-sizes uf) root)))

(defun uf-roots (uf)
  "Return a list of all distinct canonical roots in the forest."
  (let ((parents (union-find-parents uf))
        (roots nil))
    (dotimes (i (fill-pointer parents) (nreverse roots))
      (when (= i (aref parents i))
        (push i roots)))))
