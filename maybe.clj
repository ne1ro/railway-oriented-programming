(defn maybe-country [user]
  (some-> user :address :country :name .toUpperCase))

(defn country [user]
  (-> user :address :country :name .toUpperCase))

(country {:address {:country {:name nil}}})

(maybe-country {})
(maybe-country {:address {:country nil}})
(maybe-country {:address {:country {:name "germany"}}})
