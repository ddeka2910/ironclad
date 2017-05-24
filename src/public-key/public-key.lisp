;;;; -*- mode: lisp; indent-tabs-mode: nil -*-
;;;; public-key.lisp -- implementation of common public key components

(in-package :crypto)


;;; class definitions

(defclass discrete-logarithm-group ()
  ((p :initarg :p :reader group-pval)
   (q :initarg :q :reader group-qval)
   (g :initarg :g :reader group-gval)))


;;; generic definitions

(defgeneric make-public-key (kind &key &allow-other-keys)
  (:documentation "Return a public key of KIND, initialized according to
the specified keyword arguments."))

(defgeneric make-private-key (kind &key &allow-other-keys)
  (:documentation "Return a private key of KIND, initialized according to
the specified keyword arguments."))

(defgeneric generate-key-pair (kind &key num-bits &allow-other-keys)
  (:documentation "Generate a new key pair. The first returned
value is the secret key, the second value is the public key.
If KIND is :RSA, :ELGAMAL or :DSA, NUM-BITS must be specified."))

(defgeneric make-signature (kind &key &allow-other-keys)
  (:documentation "Build the octet vector representing a signature
from its elements."))

(defgeneric destructure-signature (kind signature)
  (:documentation "Return a plist containing the elements of a SIGNATURE."))

(defgeneric sign-message (key message &key start end &allow-other-keys)
  (:documentation "Produce a key-specific signature of MESSAGE; MESSAGE is a
(VECTOR (UNSIGNED-BYTE 8)).  START and END bound the extent of the
message."))

(defgeneric verify-signature (key message signature &key start end &allow-other-keys)
  (:documentation "Verify that SIGNATURE is the signature of MESSAGE using
KEY.  START and END bound the extent of the message."))

(defgeneric make-message (kind &key &allow-other-keys)
  (:documentation "Build the octet vector representing a message
from its elements."))

(defgeneric destructure-message (kind message)
  (:documentation "Return a plist containing the elements of
an encrypted MESSAGE."))

(defgeneric encrypt-message (key message &key start end &allow-other-keys)
  (:documentation "Encrypt MESSAGE with KEY.  START and END bound the extent
of the message.  Returns a fresh octet vector."))

(defgeneric decrypt-message (key message &key start end &allow-other-keys)
  (:documentation "Decrypt MESSAGE with KEY.  START and END bound the extent
of the message.  Returns a fresh octet vector."))

(defgeneric diffie-hellman (private-key public-key)
  (:documentation "Compute a shared secret using Alice's PRIVATE-KEY and Bob's PUBLIC-KEY"))


;;; converting from integers to octet vectors

(defun octets-to-integer (octet-vec &key (start 0) end (big-endian t) n-bits)
  (declare (type (simple-array (unsigned-byte 8) (*)) octet-vec)
           (optimize (speed 3) (space 0) (safety 1) (debug 0)))
  (let ((end (or end (length octet-vec))))
    (multiple-value-bind (complete-bytes extra-bits)
        (if n-bits
            (truncate n-bits 8)
            (values (- end start) 0))
      (declare (ignorable complete-bytes extra-bits)) ;; TODO: don't ignore the n-bits parameter
      (if big-endian
          (do ((j start (1+ j))
               (sum 0))
              ((>= j end) sum)
            (setf sum (+ (aref octet-vec j) (ash sum 8))))
          (loop for i from (- end start 1) downto 0
                for j from (1- end) downto start
                sum (ash (aref octet-vec j) (* i 8)))))))

(defun integer-to-octets (bignum &key (n-bits (integer-length bignum))
                                   (big-endian t))
  (declare (optimize (speed 3) (space 0) (safety 1) (debug 0)))
  (let* ((n-bytes (ceiling n-bits 8))
         (octet-vec (make-array n-bytes :element-type '(unsigned-byte 8))))
    (declare (type (simple-array (unsigned-byte 8) (*)) octet-vec))
    (if big-endian
        (loop for i from (1- n-bytes) downto 0
              for index from 0
              do (setf (aref octet-vec index) (ldb (byte 8 (* i 8)) bignum))
              finally (return octet-vec))
        (loop for i from 0 below n-bytes
              for byte from 0 by 8
              do (setf (aref octet-vec i) (ldb (byte 8 byte) bignum))
              finally (return octet-vec)))))

(defun maybe-integerize (thing)
  (etypecase thing
    (integer thing)
    ((simple-array (unsigned-byte 8) (*)) (octets-to-integer thing))))
